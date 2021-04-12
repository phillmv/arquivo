# should be run after the EntryTagger, since we rely on Entry tags
class EntryLinker
  URL_REGEX = Regexp.new("(#{URI.regexp})", true)
  WIKILINK_REGEX = /\[\[([^\]|]*)(\|([^\]]*))?\]\]/
  attr_reader :entry

  def initialize(entry)
    @entry = entry
  end

  def extract_urls(body)
    urls = body&.scan(URL_REGEX)&.map(&:first)&.flatten || []
    wiki_urls = body&.scan(WIKILINK_REGEX)&.map(&:first) || []

    urls + wiki_urls
  end

  def link!
    notebook = Notebook.find_by!(name: entry.notebook)

    links = extract_urls(entry.body).map do |url|
      link = notebook.links.find_by(url: url)

      if link.nil?
        link = notebook.links.create(url: url)
      end

      link
    end

    entry.links = links
  end
end
