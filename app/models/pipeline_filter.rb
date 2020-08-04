module PipelineFilter
  # we just want to tweak the default whitelist a little bit
  # and allow the data-sourcepos attribute to go thru
  ENTRY_SANITIZATION_WHITELIST = HTML::Pipeline::SanitizationFilter::WHITELIST.dup
  ESW = ENTRY_SANITIZATION_WHITELIST
  ESW[:attributes] = ESW[:attributes].dup
  ESW[:attributes][:all] = ESW[:attributes][:all].dup
  ESW[:attributes][:all].push("data-sourcepos")

  # nota bene:
  # must use MarkdownFilter with unsafe
  # which means must use SanitizationFilter
  # which means must not have CommonMarker insert TaskLists and
  # instead must have a filter transform AFTER sanitization

  ENTRY_PIPELINE = HTML::Pipeline.new [
    PipelineFilter::MarkdownFilter,
    HTML::Pipeline::SanitizationFilter,
    PipelineFilter::MyTaskListFilter,
    PipelineFilter::HashtagFilter,
    PipelineFilter::MentionFilter,
    HTML::Pipeline::TableOfContentsFilter,
    HTML::Pipeline::ImageMaxWidthFilter,
  ], { unsafe: true,
       commonmarker_render_options: [:SOURCEPOS],
       whitelist: ENTRY_SANITIZATION_WHITELIST
  }

end
