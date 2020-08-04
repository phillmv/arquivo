class EntryTagger
  attr_reader :entry

  def initialize(entry)
    @entry = entry
  end

  def extract_tags
    entry.body&.scan(PipelineFilter::HashtagFilter::HASHTAG_REGEX)&.flatten || []
  end

  def process!
    extract_tags.each do |name|
      Tag.transaction do
        tag = Tag.find_by(notebook: entry.notebook,
                          name: name)

        if tag
          if tag.updated_at < entry.updated_at
            tag.update(updated_at: entry.updated_at)
          end
        else
          Tag.create(notebook: entry.notebook,
                     name: name,
                     updated_at: entry.updated_at)
        end
      end
    end
  end
end
