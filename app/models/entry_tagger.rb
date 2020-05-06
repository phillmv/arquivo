class EntryTagger
  attr_reader :entry, :renderer

  def initialize(entry)
    @entry = entry
    @renderer = EntryRenderer.new(entry)
  end

  def process!
    extract_tags.each do |name|
      Tag.transaction do
        tag = Tag.find_by(notebook: entry.notebook,
                          name: name)

        if tag
          if tag.updated_at < entry.updated_at
            tag.update_attributes(updated_at: entry.updated_at)
          end
        else
          Tag.create(notebook: entry.notebook,
                     name: name,
                     updated_at: entry.updated_at)
        end
      end
    end
  end

  # for now, let's only look at the body for tags?
  # probably will want to skip non web entries
  def extract_tags
    renderer.to_html("body").
      scan(EntryRenderer::HASHTAG_REGEX).flatten
  end
end
