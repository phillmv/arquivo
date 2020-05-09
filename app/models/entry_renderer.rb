require 'task_list/filter'
class EntryRenderer
  HASHTAG_REGEX = /(\s|^)(?<hashtag>#[A-Za-z0-9\-\.\_]+)/

  # quick hack to incorporate hashtags into the pipeline, see below.
  class HashtagFilter < HTML::Pipeline::Filter
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
      str.gsub(EntryRenderer::HASHTAG_REGEX) do |match|
        "<a href=\"#{search_url(match)}\">#{match}</a>"
      end
    end

    def search_url(str)
      Rails.application.routes.url_helpers.search_path(notebook: context[:entry].notebook, query: str)
    end

  end

  # nota bene:
  # must use MarkdownFilter with unsafe
  # which means must use SanitizationFilter
  # which means must not have CommonMarker insert TaskLists and
  # instead must have a filter transform AFTER sanitization
  PIPELINE = HTML::Pipeline.new [
    HTML::Pipeline::MarkdownFilter,
    HTML::Pipeline::SanitizationFilter,
    TaskList::Filter,
    HashtagFilter,
    HTML::Pipeline::TableOfContentsFilter,
    HTML::Pipeline::ImageMaxWidthFilter,
  ], { unsafe: true }

  attr_accessor :entry, :notebook
  def initialize(entry)
    @entry = entry
    @notebook = entry.notebook
  end

  def to_html(attribute_name = "body")
    attribute = entry.attributes[attribute_name]
    if !attribute
      ""
    else
      PIPELINE.to_html(attribute, entry: entry).html_safe
    end
  end

  # TODO: fold this into the HashtagFilter, maybe?
  def extract_tags
    entry.body.scan(HASHTAG_REGEX).flatten
  end
end
