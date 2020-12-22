# should be run after the EntryTagger, since we rely on Entry tags
class EntryLinker
  URL_REGEX = Regexp.new("(#{URI.regexp})", true)
  attr_reader :entry

  def initialize(entry)
    @entry = entry
  end

  def extract_urls(body)
    body&.scan(URL_REGEX)&.map(&:first)&.flatten || []
  end

  def link!
    return # do nothing for now

    # let's not link bookmarks / avoid circularity
    if entry.bookmark?
      return
    end

    notebook = Notebook.find_by!(name: entry.notebook)

    links = extract_urls(entry.body).map do |url|
      link = notebook.entries.find_by_url(url)

      if link
        if link.body.blank?
          # if the body remains empty, let's port over tags if any?
          link.update(body: entry.tags.join(" "))
        end
      else
        link = notebook.entries.create(kind: "pinboard",
                                       url: url,
                                       subject: url,
                                       body: entry.tags.join(" "))
      end

      link
    end

    entry.links = links
  end
end
