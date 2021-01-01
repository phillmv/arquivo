# The values of an Entry are as follows:
# - "dumb" (as in simple) but sturdy
# - an Entry should denote something that has *happened*, i.e.  if the
#   occurred_at date is in the future, then maybe you want a diff object?
# - entries can be edited by the user, but if inserted by a robot should be
#   treated as immutable, or as close as it is sensible.
class Entry < ApplicationRecord
  has_many_attached :files

  # TODO: dear LORD rename this column, lmao, way too confusing to have a Notebook object and a notebook string.
  belongs_to :parent_notebook, foreign_key: :notebook, primary_key: :name, class_name: 'Notebook'

  scope :visible, -> { where(hide: false) }
  scope :for_notebook, -> (notebook) { where(notebook: notebook.to_s) }
  scope :hitherto, -> { where("occurred_at <= ? ", Time.current.end_of_day) }
  scope :upcoming, -> { where("occurred_at > ? ", Time.now) }
  # used in Search
  scope :before, -> (date) { where("occurred_at < ?", date) }
  scope :after, -> (date) { where("occurred_at >= ?", date) }
  # ---
  scope :today, -> { where("occurred_at >= ? and occurred_at <= ?", Time.current.beginning_of_day, Time.current.end_of_day) }

  scope :notes , -> { where("kind is null") }
  scope :except_calendars, -> { where("kind is null OR kind != ?", "calendar") }
  scope :calendars, -> { where(kind: "calendar") }
  scope :bookmarks, -> { where(kind: "pinboard") }
  scope :except_bookmarks, -> { where(kind: nil).or(where.not(kind: "pinboard")) }

  scope :with_todos, -> { joins(:todo_list).where("todo_lists.completed_at": nil) }
  scope :with_completed_todos, -> { joins(:todo_list).where("todo_lists.completed_at is not null") }

  scope :with_files, -> { joins(:files_attachments) }

  has_many :replies, class_name: "Entry", foreign_key: :in_reply_to, primary_key: :identifier
  belongs_to :parent, class_name: "Entry", foreign_key: :in_reply_to, primary_key: :identifier, optional: true

  has_many :tag_entries
  has_many :tags, through: :tag_entries

  has_many :contact_entries
  has_many :contacts, through: :contact_entries

  has_one :todo_list
  has_many :todo_list_items, through: :todo_list

  has_many :link_entries
  has_many :links, through: :link_entries

  validates :identifier, uniqueness: { scope: :notebook }
  before_create :set_identifier
  attr_accessor :skip_local_sync # skip sync to git
  after_save :sync_to_git, :process_tags, :process_contacts, :process_todo_list, :process_link_entries, :clear_cached_blob_filenames

  def set_identifier
    self.occurred_at ||= Time.current
    if self.bookmark?
      # TODO: pinboard uses MD5, do I have to use MD5??
      self.identifier = Digest::MD5.hexdigest(self.url)
    else
      self.identifier ||= Entry.generate_identifier(occurred_at)
    end
  end

  # We use the OLC alphabet to minimize chances of spelling dumb words
  # https://github.com/google/open-location-code/blob/master/docs/olc_definition.adoc#open-location-code
  B20_ALPHABET = "0123456789abcdefghij"
  OLC_ALPHABET = "23456789cfghjmpqrvwx"

  # TODO: retry in case of collisions?
  # Rare for this use case, but… ya never know!

  def self.generate_identifier(datetime, hash_to_be = nil)
    str = datetime.strftime("%Y%m%d%H%M%S")

    suffix = nil
    if hash_to_be
      # we pick 8 base(16) chars so we can be sure to fill out
      # the 7 base(20) chars it'll be converted to
      suffix = Digest::SHA256.hexdigest(hash_to_be).first(8).to_i(16).to_s(20)
    else
      suffix = SecureRandom.random_number(20 ** 4).to_s(20)
    end

    # convert to OLC alphabet
    suffix = suffix.tr(B20_ALPHABET, OLC_ALPHABET).first(7)

    str + "-" + suffix
  end

  # TODO: what do i gain over just search url column?
  # will i never index the url field?
  def self.find_by_url(url)
    find_by(identifier: Digest::MD5.hexdigest(url))
  end

  # -- after_save
  def process_todo_list
    TodoListMaker.new(self).make!
  end

  def process_contacts
    EntryContactMaker.new(self).make!
  end

  def process_tags
    EntryTagger.new(self).process!
  end

  def sync_to_git
    # globally set NOP so we can skip this from within tests
    # see `enable_local_sync` in tests
    unless self.skip_local_sync || Rails.application.config.skip_local_sync
      LocalSyncer.sync_entry(self)
    end
  end

  def process_link_entries
    EntryLinker.new(self).link!
  end

  # clear this cache! this table/cache is only checked in between commits to
  # Entries, so clearing the table after saves should be safe.
  def clear_cached_blob_filenames
    CachedBlobFilename.where(notebook: self.notebook,
                             entry_identifier: self.identifier).delete_all
  end
  # --

  def note?
    kind.nil?
  end

  def calendar?
    kind == "calendar"
  end

  def bookmark?
    kind == "pinboard"
  end

  def fold?
    self.body.size > 500
  end

  def reply?
    in_reply_to.presence
  end

  def copy_parent(entry)
    if entry.calendar?
      self.body = entry.from_calendar_to_body_headline
    elsif entry.note?
      self.body = entry.body&.lines&.first
    end
  end

  def from_calendar_to_body_headline
    "#meeting #{to.present? && to&.split(", ").map { |s| "@#{s.split("@").first}" }.join(" ")}"
  end

  # -- little hack to split date from time in UI
  # if #update gets an occurred_date= attribute, it'll set the ivar
  # which is how we'll know to update the actual database column
  # meanwhile we just use a different ivar name for caching the string manip

  attr_writer :occurred_date, :occurred_time
  before_save :set_occurred_date

  def set_occurred_date
    if @occurred_date
      self.occurred_at = "#{@occurred_date} #{@occurred_time}"
    end
  end

  def occurred_date
    @occurred_date_cache ||= occurred_at.to_date
  end

  def occurred_time
    @occurred_time_cache ||= occurred_at.strftime("%H:%M:%S %z")
  end


  # this is actually pretty complicated to do properly?
  # https://github.com/middleman/middleman/blob/master/middleman-core/lib/middleman-core/util/data.rb
  # https://github.com/middleman/middleman/blob/master/middleman-core/lib/middleman-core/core_extensions/front_matter.rb
  # https://github.com/middleman/middleman/blob/5fd6a1efcb7a5f1cb6b3dbe3c930fddc91b3e626/middleman-core/lib/middleman-core/util/binary.rb#L357
  #
  # meh handle later
  # https://stackoverflow.com/questions/36948807/edit-yaml-frontmatter-in-markdown-file
  def frontmatter_attributes
    self.attributes.slice("id",
                          "occurred_at",
                          "created_at",
                          "updated_at")
  end

  def revisions
    @history ||= EntryHistory.new(self)
    @history.revisions
  end

  def to_param
    identifier
  end

  def export_attributes
    attributes.except("id")
  end

  def to_yaml
    export_attributes.to_yaml
  end

  def to_folder_path(arquivo_path)
    File.join(arquivo_path,
              notebook,
              occurred_at.strftime("%Y/%m/%d"),
              identifier)
  end

  def to_relative_file_path
    File.join(occurred_at.strftime("%Y/%m/%d"),
              identifier,
              to_filename)
  end

  def to_filename
    "#{identifier}.yaml"
  end

  def to_full_file_path(arquivo_path)
    File.join(to_folder_path(arquivo_path), to_filename)
  end

  def truncated_description(n = 30)
    (subject || body || "").truncate(n)
  end
end
