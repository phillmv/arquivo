module PipelineFilter
  # we just want to tweak the default whitelist a little bit
  # and allow the data-sourcepos attribute to go thru
  # without this change the data-sourcepos gets stripped
  ENTRY_SANITIZATION_WHITELIST = HTML::Pipeline::SanitizationFilter::WHITELIST.dup
  ESW = ENTRY_SANITIZATION_WHITELIST
  ESW[:elements] = ESW[:elements].dup
  ESW[:elements] << "table-of-contents"
  ESW[:elements] << "section"

  ESW[:attributes] = ESW[:attributes].dup
  # used for enabling footnotes
  ESW[:attributes]['a'] = ESW[:attributes]['a'].dup
  ESW[:attributes]['a'].push("id")
  ESW[:attributes]['a'].push("class")
  ESW[:attributes]['sup'] = ['class']
  ESW[:attributes]['li'] = ['id']
  # end footnotes

  # used for enabling task lists in js
  ESW[:attributes][:all] = ESW[:attributes][:all].dup
  ESW[:attributes][:all].push("data-sourcepos")

  # nota bene:
  # must use MarkdownFilter with unsafe
  # which means must use SanitizationFilter
  # which means must not have CommonMarker insert TaskLists and
  # instead must have a filter transform AFTER sanitization

  ENTRY_PIPELINE = HTML::Pipeline.new [
    PipelineFilter::MarkdownFilter, # convert to HTML
    PipelineFilter::WikiLinkFilter,
    HTML::Pipeline::SanitizationFilter, # strip scary tags
    PipelineFilter::MyTaskListFilter, # convert task markdown to html
    PipelineFilter::HashtagFilter, # link hashtags
    PipelineFilter::MentionFilter, # link mentions
    PipelineFilter::TableOfContentsFilter, # ids to headers, toc tag
    HTML::Pipeline::ImageMaxWidthFilter, # max 100% for imgs
  ], { unsafe: true,
       space_replacement: "-",
       commonmarker_render_options: [:SOURCEPOS],
       whitelist: ENTRY_SANITIZATION_WHITELIST
  }

end
