class EntryRenderer
  attr_accessor :entry, :notebook
  CMARK_OPT = [:GITHUB_PRE_LANG, :HARDBREAKS]
  CMARK_EXT = [:table, :tasklist, :autolink, :strikethrough]

  HASHTAG_REGEX = /\B(#[A-Za-z0-9\-\.\_]+)/

  def initialize(entry)
    @entry = entry
    @notebook = entry.notebook
  end

  def to_html(attribute_name = "body")
    attribute = entry.attributes[attribute_name]
    if !attribute
      ""
    else
      # pipeline. first we render the markdown
      html_from_md = CommonMarker.render_html(attribute, CMARK_OPT, CMARK_EXT)

      # then we render hashtags
      final_html = render_hashtags(html_from_md)
      final_html.html_safe
    end
  end

  def render_hashtags(str)
    str.gsub(HASHTAG_REGEX) do |match|
      "<a href=\"#{search_url(match)}\">#{match}</a>"
    end
  end

  def search_url(str)
    Rails.application.routes.url_helpers.search_path(notebook: notebook, query: str)
  end
end
