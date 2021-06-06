# quick hack to incorporate hashtags into the pipeline, see below.
class PipelineFilter::HashtagFilter < HTML::Pipeline::Filter
  HASHTAG_REGEX = /(\s|^)(?<hashtag>#[A-Za-z0-9\-\.\_]+)/

  # Don't look for mentions in text nodes that are children of these elements
  IGNORE_PARENTS = %w(pre code a style script).to_set
  def call
    doc.search('.//text()').each do |node|
      content = node.to_html
      next unless content.include?('#')
      next if has_ancestor?(node, IGNORE_PARENTS)
      html = render_hashtags(content)
      next if html == content
      node.replace(html)
    end
    doc
  end

  def render_hashtags(str)
    str.gsub(HASHTAG_REGEX) do |match|
      stripped_match = match.strip
      " <a href=\"#{search_url(stripped_match)}\">#{stripped_match}</a>"
    end
  end

  def search_url(str)
    if Arquivo.static?
      Rails.application.routes.url_helpers.tag_path(query: str.gsub("#", ""))
    else
      Rails.application.routes.url_helpers.search_path(owner: context[:entry].parent_notebook.owner, notebook: context[:entry].notebook, query: str)
    end
  end
end
