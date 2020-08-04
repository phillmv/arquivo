require 'task_list/filter'
class TodoRenderer
  attr_accessor :entry
  def initialize(entry)
    @entry = entry
  end

  PIPELINE = HTML::Pipeline.new [
    PipelineFilter::MarkdownFilter,
    HTML::Pipeline::SanitizationFilter,
    TaskList::Filter,
    PipelineFilter::OnlyTodoFilter,
    PipelineFilter::HashtagFilter,
    PipelineFilter::MentionFilter,
    HTML::Pipeline::TableOfContentsFilter,
    HTML::Pipeline::ImageMaxWidthFilter,
  ], { unsafe: true,
       whitelist: PipelineFilter::ENTRY_SANITIZATION_WHITELIST,
       commonmarker_render_options: [:SOURCEPOS]
  }

  # TODO: to_html should accept… a string, right?
  # more importantly: cache the results, so that we may
  # filter out empty entries

  def to_html(attribute_name = "body")
    attribute = entry.attributes[attribute_name]
    attribute ||= entry.send(attribute_name) if attribute_name == "todo_body"
    if !attribute
      ""
    else
      PIPELINE.to_html(attribute, entry: entry, todo_only: true).html_safe
    end

  end
end
