class EntryTagger
  attr_reader :entry

  def initialize(entry)
    @entry = entry
  end

  def extract_tags(entry)
    (entry.body&.scan(PipelineFilter::HashtagFilter::HASHTAG_REGEX)&.flatten || []) + metadata_tags(entry)
  end

  def process!
    tag_list = extract_tags(entry).map do |name|
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

  def metadata_tags(entry)
    tags = (entry.metadata["tags"] || entry.metadata[:tags])
    tags = case tags
    when Array
      tags
    when String
      tags.split(",")
    else
      []
    end

    # tags may not contain spaces
    tags = tags.map { |s| s.split(" ") }.flatten

    # force every tag to start with a #
    tags.map do |s|
      if s[0] != "#"
        "##{s}"
      else
        s
      end
    end
  end
end
