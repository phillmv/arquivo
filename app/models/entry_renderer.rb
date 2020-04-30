class EntryRenderer
  attr_accessor :entry, :current_notebook
  delegate :body, to: :entry
  CMARK_OPT = [:GITHUB_PRE_LANG, :HARDBREAKS]
  CMARK_EXT = [:table, :tasklist, :autolink, :strikethrough]

  HASHTAG_REGEX = /\B(#[A-Za-z0-9\-\.\_]+)/

  def initialize(current_notebook, entry)
    @entry = entry
    @current_notebook = current_notebook
  end

  def to_html
    if !body
      ""
    else
      # pipeline. first we render the markdown
      html_from_md = CommonMarker.render_html(body, CMARK_OPT, CMARK_EXT)

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
    Rails.application.routes.url_helpers.search_path(notebook: current_notebook, query: str)
  end
end
