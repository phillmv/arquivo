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
