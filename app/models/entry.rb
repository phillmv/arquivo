class Entry < ApplicationRecord
  has_many_attached :files

  scope :for_notebook, -> (notebook) { where(notebook: notebook.name) }
  scope :hitherto, -> { where("occurred_at <= ? ", Time.now) }
  scope :upcoming, -> { where("occurred_at > ? ", Time.now) }

  before_create :set_identifier

  def set_identifier
    self.identifier ||= Time.current.strftime("%Y-%m-%d-%H%M%S%L")
  end

  def calendar?
    kind == "calendar"
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
end
