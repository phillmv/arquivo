class EntryTagger
  attr_reader :entry

  def initialize(entry)
    @entry = entry
  end

  def extract_tags(body)
    body&.scan(PipelineFilter::HashtagFilter::HASHTAG_REGEX)&.flatten || []
  end

  def process!
    tag_list = extract_tags(entry.body).map do |name|
      Tag.transaction do
        tag = Tag.find_by(notebook: entry.notebook,
                          name: name)

        if tag
          if tag.updated_at < entry.updated_at
            tag.update(updated_at: entry.updated_at)
          end
        else
          tag = Tag.create(notebook: entry.notebook,
                     name: name,
                     updated_at: entry.updated_at)
        end

        tag
      end
    end

    old_tags = entry.tags - tag_list
    entry.tags = tag_list

    old_tags.each(&:apoptosis!)

    tag_list
  end
end
