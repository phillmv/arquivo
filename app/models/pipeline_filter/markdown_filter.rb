# For reasons I do not comprehend, CommonMarker distinguishes between render
# and parse options, throwing an error should you pass in a flag enabling a
# parse bitmask that is not defined as a render option.
#
# Also confusingly, it's not obvious how to pass along parse vs render options.
#
# However, if you forcibly pass in the FOOTNOTES bitmask into the render
# options… it just works??
#
# I have not yet gone thru the C code to try to understand wtf is going on
# (and tbh I idk that I'd get this thru as a PR) but in the meantime here is
# an insanely silly hack that adds the FOOTNOTES bitmask option to the Render
# Config class, thereby allowing me to pass it along as an option to
# CommonMarker#render_html.
module CommonMarker
  module Config
    class Render
      define :FOOTNOTES, (1 << 13)
    end
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
