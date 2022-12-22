require 'task_list/filter'
class EntryRenderer
  attr_accessor :entry, :output, :html
  
  # avail options:
  # todo_only: true
  # smart_punctuation: true
  # remove_subject: true
  def initialize(entry, opt = {})
    @entry = entry
    @options = {
      sanitize: true
    }.merge(entry.parent_notebook.settings.render_options).merge(opt)
    @output = {}
    @html = {}
  end

  ## what is the api i want for this? it should cache the output.
  def pipeline(opt = {})
    if (opt[:sanitize] || @options[:sanitize]) == true
      SAFE_PIPELINE
    else
      UNSAFE_PIPELINE
    end
  end

  # do we take an attribute? we're rendering an entry when was the last fucking time i rendered something other than a body?

  def render(opt = {})
    @output[opt] ||= pipeline.call(entry.body, @options.merge(opt).merge(entry: entry))
  end

  # as the name itself indicates, to_html2 is a transitional method while I
  # hammer out how the renderer itself should work. i'm pretty convinced the
  # renderer should have a built-in cache, but at the time of writing (TODO)
  # i have yet to extend this refactor to the rest of the views
  def to_html2(opt = {})
    @html[opt] ||= render(opt)[:output].to_html.html_safe
  end

  # -- as we used to do it follows:
  # TODO: to_html should accept… a string, maybe?
  # not clear how this api should work.
  # should it accept: an attribute, a method, a full string?, a flag (i.e. :todo)
  # or just make everything a named keyword.

  def to_html(attribute_name = "body", opt = {})
    attribute = entry.attributes[attribute_name]
    if !attribute
      ""
    else
      render_html(attribute, opt)
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
    render[:entry_subject]
  end

  def subject_html
    render[:entry_subject_html]&.html_safe
  end

  def gimme_html(str)
    SAFE_PIPELINE.to_html(str, entry: entry).html_safe
  end

  def render_body(opt = {})
    render_html(entry.body, opt)
  end

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

  # used for keeping track of which links come from [[]] wiki syntax
  # in order to facilitate the EntryLinker's job:
  ESW[:attributes]['a'].push("data-wikify")
  # ESW[:attributes]['a'].push("class")  # used for making certain links red if not yet made / not strictly necessary?
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
    PipelineFilter::WikiLinkFilter,
    HTML::Pipeline::SanitizationFilter, # strip scary tags
    PipelineFilter::MyTaskListFilter, # convert task markdown to html
    PipelineFilter::HashtagFilter, # link hashtags
    PipelineFilter::MentionFilter, # link mentions
    PipelineFilter::SubjectExtractorFilter, # TODO: does it matter if we extract the subject before or after the hash & mention filter? this could mess stuff up in static mode (i.e. the unsafe pipeline)
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
end
