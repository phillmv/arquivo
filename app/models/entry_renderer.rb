require 'task_list/filter'
class EntryRenderer
  # we just want to tweak the default whitelist a little bit
  # and allow the data-sourcepos attribute to go thru
  # without this change the data-sourcepos gets stripped
  ENTRY_SANITIZATION_WHITELIST = HTML::Pipeline::SanitizationFilter::WHITELIST.dup
  ESW = ENTRY_SANITIZATION_WHITELIST
  ESW[:elements] = ESW[:elements].dup
  ESW[:elements] << "table-of-contents"

  ESW[:attributes] = ESW[:attributes].dup

  # used for enabling footnotes
  # i don't love these footnote exceptions. Might have to create a custom
  # transformer for it or something. How to prevent potential xss on `id`, `class`?
  ESW[:elements] << "section"
  # ESW[:attributes]['section'] = ['class'] # not strictly necessary?
  ESW[:attributes]['a'] = ESW[:attributes]['a'].dup
  ESW[:attributes]['a'].push("id")
  # ESW[:attributes]['a'].push("class")  # not strictly necessary?
  # ESW[:attributes]['sup'] = ['class']  # not strictly necessary?
  ESW[:attributes]['li'] = ['id']
  # end footnotes

  # used for enabling task lists in js
  ESW[:attributes][:all] = ESW[:attributes][:all].dup
  ESW[:attributes][:all].push("data-sourcepos")
  # end task lists

  DEFAULT_CMARK_RENDER_OPT = [:SOURCEPOS]
  SMART_CMARK_RENDER_OPT = [:SOURCEPOS, :SMART]

  # nota bene:
  # must use MarkdownFilter with unsafe
  # which means must use SanitizationFilter
  # which means must not have CommonMarker insert TaskLists and
  # instead must have a filter transform AFTER sanitization

  SAFE_PIPELINE = HTML::Pipeline.new [
    PipelineFilter::MarkdownFilter, # convert to HTML
    PipelineFilter::SubjectExtractorFilter,
    PipelineFilter::WikiLinkFilter,
    HTML::Pipeline::SanitizationFilter, # strip scary tags
    PipelineFilter::MyTaskListFilter, # convert task markdown to html
    PipelineFilter::HashtagFilter, # link hashtags
    PipelineFilter::MentionFilter, # link mentions
    PipelineFilter::TableOfContentsFilter, # ids to headers, toc tag
    HTML::Pipeline::ImageMaxWidthFilter, # max 100% for imgs
  ], { unsafe: true,
       space_replacement: "-", # used in WikiLink filter
       commonmarker_render_options: DEFAULT_CMARK_RENDER_OPT,
       whitelist: ENTRY_SANITIZATION_WHITELIST
  }

  # Exactly the same as the SAFE_PIPELINE but minus the sanitizationfilter
  UNSAFE_PIPELINE = HTML::Pipeline.new [
    PipelineFilter::MarkdownFilter, # convert to HTML
    PipelineFilter::SubjectExtractorFilter,
    PipelineFilter::WikiLinkFilter,
    # Here we commented out: HTML::Pipeline::SanitizationFilte
    PipelineFilter::MyTaskListFilter, # convert task markdown to html
    PipelineFilter::HashtagFilter, # link hashtags
    PipelineFilter::MentionFilter, # link mentions
    PipelineFilter::TableOfContentsFilter, # ids to headers, toc tag
    HTML::Pipeline::ImageMaxWidthFilter, # max 100% for imgs
  ], { unsafe: true,
       space_replacement: "-", # used in WikiLink filter,
       commonmarker_extensions: [:table, :strikethrough, :autolink], # of note: this lacks the tagfilter extension
       commonmarker_render_options: DEFAULT_CMARK_RENDER_OPT,
       # now redundant: whitelist: ENTRY_SANITIZATION_WHITELIST
  }


  attr_accessor :entry
  def initialize(entry, opt = {})
    @entry = entry
    @options = {
      sanitize: true
    }.merge(entry.parent_notebook.settings.render_options).merge(opt)
  end

  # TODO: to_html should accept… a string, maybe?
  # not clear how this api should work.
  # should it accept: an attribute, a method, a full string?, a flag (i.e. :todo)
  # or just make everything a named keyword.

  def to_html(attribute_name = "body")
    attribute = entry.attributes[attribute_name]
    if !attribute
      ""
    else
      render_html(attribute)
    end
  end

  def render_html(str, opt = {})
    pipeline_opt = { entry: entry }
    if opt[:smart_punctuation] || @options[:smart_punctuation]
      pipeline_opt[:commonmarker_render_options] = SMART_CMARK_RENDER_OPT
    end
    pipeline_opt = pipeline_opt.merge(opt)

    # if we've explicitly set sanitize to false, ie not just nil,
    # then & only then we can use the UNSAFE pipeline.
    if (opt[:sanitize] == false || @options[:sanitize] == false)
      UNSAFE_PIPELINE.to_html(str, pipeline_opt).html_safe
    else
      SAFE_PIPELINE.to_html(str, pipeline_opt).html_safe
    end
  end

  # i don't love this - maybe this should be folded into #to_html
  # but for now this is easy to cache
  def todo_to_html
    @todo_to_html ||= render_html(entry.body, todo_only: true)
  end

  def task_list_items
    SAFE_PIPELINE.call(entry.body, entry: entry)[:task_list_items]
  end

  def subject
    SAFE_PIPELINE.call(entry.body, entry: entry)[:entry_subject]
  end

  def subject_html
    SAFE_PIPELINE.call(entry.body, entry: entry)[:entry_subject_html]&.html_safe
  end

  def gimme_html(str)
    SAFE_PIPELINE.to_html(str, entry: entry).html_safe
  end

  def render_body(opt = {})
    render_html(entry.body, opt)
  end
end
