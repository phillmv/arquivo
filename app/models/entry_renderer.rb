require 'task_list/filter'
class EntryRenderer
  # nota bene:
  # must use MarkdownFilter with unsafe
  # which means must use SanitizationFilter
  # which means must not have CommonMarker insert TaskLists and
  # instead must have a filter transform AFTER sanitization
  PIPELINE = HTML::Pipeline.new [
    PipelineFilter::MarkdownFilter,
    HTML::Pipeline::SanitizationFilter,
    TaskList::Filter,
    PipelineFilter::HashtagFilter,
    PipelineFilter::MentionFilter,
    HTML::Pipeline::TableOfContentsFilter,
    HTML::Pipeline::ImageMaxWidthFilter,
  ], { unsafe: true,
       commonmarker_render_options: [:SOURCEPOS],
       whitelist: PipelineFilter::ENTRY_SANITIZATION_WHITELIST
  }

  attr_accessor :entry, :notebook
  def initialize(entry)
    @entry = entry
    @notebook = entry.notebook
  end

  def to_html(attribute_name = "body")
    attribute = entry.attributes[attribute_name]
    attribute ||= entry.send(attribute_name) if attribute_name == "todo_body"
    if !attribute
      ""
    else
      PIPELINE.to_html(attribute, entry: entry).html_safe
    end
  end

  # TODO: fold this into the HashtagFilter, maybe?
  def extract_tags
    entry.body&.scan(PipelineFilter::HashtagFilter::HASHTAG_REGEX)&.flatten || []
  end
end
