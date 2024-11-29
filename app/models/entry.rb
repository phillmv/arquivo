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
  scope :hidden, -> { where(hide: true) }
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
  scope :documents, -> { where(kind: "document") }
  scope :manifests, -> { where(kind: "manifest") }
  scope :templates, -> { where(kind: "templates") }

  scope :with_todos, -> { joins(:todo_list).where("todo_lists.completed_at": nil) }
  scope :with_completed_todos, -> { joins(:todo_list).where("todo_lists.completed_at is not null") }

  scope :with_files, -> { joins(:files_attachments) }

  # has_many :replies, class_name: "Entry", foreign_key: :in_reply_to, primary_key: :identifier
  def replies
    self.parent_notebook.entries.where(in_reply_to: self.identifier)
  end
  # belongs_to :parent, class_name: "Entry", foreign_key: :in_reply_to, primary_key: :identifier, optional: true
  def parent
    self.parent_notebook.entries.find_by(identifier: self.in_reply_to)
  end

  def thread_ancestors
    thread_root = self.parent_notebook.entries.where(identifier: self.thread_identifier)
    self.parent_notebook.entries.where("thread_identifier = ? and occurred_at <= ? and identifier != ?", self.thread_identifier, self.occurred_at, self.identifier).or(thread_root).order(occurred_at: :desc)
  end

  def thread_descendants
    # replies to this entry
    query = self.parent_notebook.entries.where(thread_identifier: self.identifier)

    if self.thread_identifier
      # other replies in this thread
      query = query.or(self.parent_notebook.entries.where(thread_identifier: self.thread_identifier))
    end

    query.where("occurred_at >= ? and identifier != ?", self.occurred_at, self.identifier).order(occurred_at: :desc)
  end

  def whole_thread
    thread_root = self.parent_notebook.entries.where(identifier: self.thread_identifier)
    self.parent_notebook.entries.where("thread_identifier = ?", self.thread_identifier).or(thread_root).order(occurred_at: :desc)
  end

  # TODO: assert dependent destroys clean up through models if relevant

  has_many :tag_entries, dependent: :destroy
  has_many :tags, through: :tag_entries

  has_many :contact_entries, dependent: :destroy
  has_many :contacts, through: :contact_entries

  has_one :todo_list, dependent: :destroy
  has_many :todo_list_items, through: :todo_list

  has_many :link_entries, dependent: :destroy
  has_many :links, through: :link_entries

  validates :identifier, uniqueness: { scope: :notebook }
  before_create :set_identifier

  # let's treat all metadata as a hash, saved as yaml
  serialize :metadata, Hash

  attr_accessor :skip_local_sync # skip sync to git
  after_save :sync_to_disk_and_git, :process_tags, :process_contacts, :process_todo_list, :process_link_entries, :clear_cached_blob_filenames
  before_save :set_subject, :set_thread_identifier

  after_destroy :sync_to_disk_and_git

  def set_identifier
    # re: Time.current.round(6),
    # On Linux systems, for reasons I haven't been able to fully investigate,
    # Time values have resolution in nanoseconds. This exceeds the precision
    # of the database column, which as of Rails 7 defaults to 6.
    # cf https://github.com/rails/rails/blob/aed8feae3b7a3f7df59de69355cc3bda1d5479d6/activerecord/lib/active_record/connection_adapters/abstract/schema_statements.rb#L1322
    #
    # This causes import/export tests to fail on Linux, since the copy in
    # memory will have a higher precision than the freshly rehydrated instance
    # that came from disk. Since we can't use nanoseconds anyways, let's just
    # round it down to microseconds.
    self.occurred_at ||= Time.current.round(6)

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
      suffix = SecureRandom.random_number(20 ** 4).to_s(20).rjust(4, "0")
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
  def should_be_processed?
    !(document? || manifest? || template?)
  end

  def process_todo_list
    if should_be_processed?
      TodoListMaker.new(self).make!
    end
  end

  def process_contacts
    if should_be_processed?
      EntryContactMaker.new(self).make!
    end
  end

  def process_tags
    if should_be_processed?
      EntryTagger.new(self).process!
    end
  end

  def set_subject
    if self.note?
      if Arquivo.static?
        # in "static" mode, sometimes the subject is set explicitly
        # so we don't want to override it. ie the attributes set a subject,
        # and then when the Entry is saved, this callback overrides it by
        # trying to guess a subject out of the entry body.
        self.subject ||= EntryRenderer.new(self).subject
      else
        # whereas in normal edit mode, the subject should always be defined
        # within the body
        self.subject = EntryRenderer.new(self, skip_notebook_settings: true).subject
      end
    end
  end

  def set_thread_identifier
    if self.in_reply_to.present? && self.thread_identifier.nil?
      self.thread_identifier = self.parent.thread_identifier || self.parent.identifier
    end
  end

  def sync_to_disk_and_git
    # globally set NOP so we can skip this from within tests
    # see `enable_local_sync` in tests
    unless self.skip_local_sync || Rails.application.config.skip_local_sync || Arquivo.static?
      SyncWithGit.new(parent_notebook).sync_entry!(self)
      PushToGitJob.perform_later(parent_notebook.id)
    end
  end

  def process_link_entries
    if should_be_processed?
      EntryLinker.new(self).link!
    end
  end

  # clear this cache! this table/cache is only checked in between commits to
  # Entries, so clearing the table after saves should be safe.
  def clear_cached_blob_filenames
    CachedBlobFilename.where(notebook: self.notebook,
                             entry_identifier: self.identifier).delete_all
  end
  # --

  def append_html_extension?
    note? || calendar? || bookmark?
  end

  def note?
    kind.nil?
  end

  def calendar?
    kind == "calendar"
  end

  def bookmark?
    kind == "pinboard"
  end

  # document type entries are treated as a kind of binary; we look up the first
  # attached file, and blindly serve it down the pipe
  def document?
    kind == "document"
  end

  def manifest?
    kind == "manifest"
  end

  def template?
    kind == "template"
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
      # TODO: test behaviour
      first_line = entry.body&.lines&.first
      if first_line
        begin
          date = Date.parse(first_line)
          first_line = first_line.gsub(date.to_s, Date.today.to_s)
        rescue ArgumentError
        end

        self.body = first_line
      end
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

  def copy_to!(notebook)
    copy = notebook.entries.find_by(identifier: self.identifier)
    if copy.present?
      copy.update!(self.export_attributes.except("notebook"))

      copy.files.destroy_all
    else
      copy = self.dup
      copy.notebook = notebook
      copy.save!
    end

    # when an object is dup'ed it keeps its existing file associations
    # which are cached and survive .reload calls. have to re-instantiate
    # the object from scratch in order to reset `copy.files`

    copy = notebook.entries.find_by(identifier: copy.identifier)

    self.files.each do |orig_file|
      orig_blob = orig_file.blob
      orig_blob.open do |tempfile|
        copy_blob = ActiveStorage::Blob.create_and_upload!(io: tempfile,
                                                           filename: orig_blob.filename,
                                                           content_type: orig_blob.content_type,
                                                           identify: false)
        copy.files.create(blob_id: copy_blob.id, created_at: copy_blob.created_at)
      end

    end

    copy.save!
    notebook.entries.find_by(identifier: copy.identifier)
  end

  ## little hack for tracking whether the identifier value returned from the
  # form was set by the user, or was just the default generated identifier.
  # this allows me to decide whether to replace the identifier with the
  # parameterized subject
  attr_accessor :generated_identifier
  def generated_identifier?
    self.generated_identifier == self.identifier
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

  # This method exists because timestamps in Rails are of TimeWithZone class.
  # The YAML serialization captures this, which causes problems in downstream
  # consumers of the yaml, i.e. the YAML can't be easily consumed by a plain
  # Ruby environment without ActiveSupport. (At time of writing, we consume
  # entry yaml for arbitrating git merge conflicts, which we resolve by picking
  # the most recently updated entry; see lib/assets/git_defaults/script/ and
  # the `SyncWithGit` class for more information). This should be Fine™,
  # since we store everything in UTC anyways.
  #
  # I feel like there's probably a better way to do this!, and keep the YAML
  # more "portable".
  def cast_twz_to_time(hash)
    hash.reduce({}) do |h, (k,v)|
      if v.is_a?(ActiveSupport::TimeWithZone)
        h[k] = v.to_time
      else
        h[k] = v
      end

      h
    end
  end

  def to_yaml
    cast_twz_to_time(export_attributes).to_yaml
  end

  def to_folder_path(arquivo_path)
    File.join(parent_notebook.to_folder_path(arquivo_path),
              occurred_at.strftime("%Y/%m/%d"),
              identifier_sanitized)
  end

  def to_relative_file_path
    File.join(occurred_at.strftime("%Y/%m/%d"),
              identifier_sanitized,
              to_filename)
  end

  def identifier_sanitized
    @identifier_sanitized ||= ActiveStorage::Filename.new(identifier).sanitized
  end

  def to_filename
    "#{identifier_sanitized}.yaml"
  end

  def to_full_file_path(arquivo_path)
    File.join(to_folder_path(arquivo_path), to_filename)
  end

  def truncated_description(n = 30)
    (subject || body || "").truncate(n)
  end

  def self.accepted_attributes
    ["notebook",
     "body",
     "metadata",
     "kind",
     "source",
     "url",
     "latitude",
     "longitude",
     "occurred_at",
     "ended_at",
     "created_at",
     "updated_at",
     "summary",
     "identifier",
     "subject",
     "from",
     "to",
     "in_reply_to",
     "state",
     "hide"]
  end

  # ---- hack
  SCSS_MANIFEST = "application.css.scss"
  def render_stylesheet!
    if self.manifest?
      load_path = File.join(parent_notebook.import_path, "stylesheets")
      manifest_path = File.join(load_path, SCSS_MANIFEST)

      if File.exist?(manifest_path)
        if body.nil? || File.mtime(manifest_path) > updated_at
          rendered_css = SassC::Engine.new(File.read(manifest_path), {
            filename: SCSS_MANIFEST,
            syntax: :scss,
            load_paths: [load_path],
          }).render

          self.body = rendered_css
          self.save!
        end
      end
    end

    self.body
  end
end
