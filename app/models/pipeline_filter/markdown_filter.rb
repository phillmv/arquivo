# For reasons I do not comprehend, CommonMarker distinguishes between render
# and parse options, throwing an error should you pass in a flag enabling a
# parse bitmask that is not defined as a render option.
#
# Also confusingly, it's not obvious how to pass along parse vs render options.
module CommonMarker
  module Config
    OPTS = OPTS.dup
    OPTS[:render] = OPTS[:render].dup
    OPTS[:render][:SMART] = (1 << 10)
  end
end

# extended from the original solely in order to add the ability to pass in
# render options via the `commonmarker_render` context flag

class PipelineFilter::MarkdownFilter < HTML::Pipeline::MarkdownFilter
  # tbh kinda dumb i had to do this.
  # for readability, removed the if statement we won't use
  def call
    extensions = context.fetch(
      :commonmarker_extensions,
      DEFAULT_COMMONMARKER_EXTENSIONS
    )
    options = [:GITHUB_PRE_LANG, :FOOTNOTES]
    options << :HARDBREAKS if context[:gfm] != false
    options << :UNSAFE if context[:unsafe]

    # here is where we allow options to be passed in
    options += context[:commonmarker_render_options] if context[:commonmarker_render_options]
    html = CommonMarker.render_html(@text, options, extensions)
    html.rstrip!
    html
  end
end
