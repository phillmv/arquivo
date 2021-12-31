# should be run after the EntryTagger, since we rely on Entry tags
class EntryLinker
  attr_reader :entry, :notebook

  def initialize(entry)
    @entry = entry
    @notebook = entry.parent_notebook
  end

  # TODO: why not add this as an optional pipeline filter? that way could avoid
  # hacks like the data-wikify attribute.
  DocumentFragment = Nokogiri::HTML::DocumentFragment
  def extract_urls
    html = EntryRenderer.new(entry).to_html2
    doc = DocumentFragment.parse(html)

    doc.css("a[href]").reduce([]) do |arr, a|
      unless reject_url?(a["href"])
        # if we have a wikify attribute, use that value instead since
        # that's what got inserted into the [[]]s
        if a["data-wikify"]
          arr << a["data-wikify"]
        else
          arr << a["href"]
        end
      end

      arr
    end
  end

  def reject_url?(href)
    # originally I went with:
    # if a["href"] =~ /^(http|\/)/
    # but on 2nd thought, the only kind of "bad" url i wouldn't consider a
    # "real" link is an anchor to something on the current path, or one of
    # the blacklisted paths.
    href[0] == "#" || blacklisted_paths.any? do |path|
      href.index(path)
    end
  end

  def blacklisted_paths
    if defined?(@blacklisted_paths)
      return @blacklisted_paths
    end

    # don't want to consider autogen tag and contact urls to be a "link"
    # since we keep track of those references separately ¯\_(ツ)_/¯
    # TODO: rewrite this to handle Arquivo.static urls
    tag_search_path = Rails.application.routes.url_helpers.search_path(owner: notebook.owner, notebook: notebook, query: "#")
    contact_search_path = Rails.application.routes.url_helpers.search_path(owner: notebook.owner, notebook: notebook, query: "@")

    @blacklisted_paths = [tag_search_path, contact_search_path]
  end

  def link!
    notebook = Notebook.find_by!(name: entry.notebook)

    links = extract_urls.map do |url|
      link = notebook.links.find_by(url: url)

      if link.nil?
        link = notebook.links.create(url: url)
      end

      link
    end

    entry.links = links
  end
end
