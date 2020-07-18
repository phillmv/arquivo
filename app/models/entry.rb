# The values of an Entry are as follows:
# - "dumb" (as in simple) but sturdy
# - an Entry should denote something that has *happened*, i.e.  if the
#   occurred_at date is in the future, then maybe you want a diff object?
# - entries can be edited by the user, but if inserted by a robot should be
#   treated as immutable, or as close as it is sensible.
class Entry < ApplicationRecord
  has_many_attached :files

  scope :visible, -> { where(hide: false) }
  scope :for_notebook, -> (notebook) { where(notebook: notebook.to_s) }
  scope :hitherto, -> { where("occurred_at <= ? ", Time.current.end_of_day) }
  scope :upcoming, -> { where("occurred_at > ? ", Time.now) }
  scope :today, -> { where("occurred_at >= ? and occurred_at <= ?", Time.current.beginning_of_day, Time.current.end_of_day) }

  scope :except_calendars, -> { where("kind is null OR kind != ?", "calendar") }
  scope :calendars, -> { where(kind: "calendar") }
  scope :bookmarks, -> { where(kind: "pinboard") }
  scope :not_bookmarks, -> { where(kind: nil).or(where.not(kind: "pinboard")) }

  has_many :replies, class_name: "Entry", foreign_key: :in_reply_to, primary_key: :identifier
  belongs_to :parent, class_name: "Entry", foreign_key: :in_reply_to, primary_key: :identifier, optional: true

  validates :identifier, uniqueness: true
  before_create :set_identifier
  after_save :process_tags

  def set_identifier
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

  def process_tags
    EntryTagger.new(self).process!
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
    end
  end

  def from_calendar_to_body_headline
    "#meeting #{to.present? && to&.split(", ").map { |s| "@#{s.split("@").first}" }.join(" ")}"
  end

  def occurred_at_date
    occurred_at.strftime("%Y-%m-%d")
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

  def to_param
    identifier
  end

  def export_attributes
    attributes.except("id")
  end

  def to_yaml
    export_attributes.to_yaml
  end

  def to_folder_path(dirname)
    File.join(dirname,
              notebook,
              occurred_at.strftime("%Y/%m/%d"),
              identifier)
  end

  def to_filename
    "#{identifier}.yaml"
  end

  def truncated_description
    (subject || body).truncate(30)
  end
end
