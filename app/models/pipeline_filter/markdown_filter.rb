# extended from the original solely in order to add the ability to pass in
# render options via the `commonmarker_render` context flag
class PipelineFilter::MarkdownFilter < HTML::Pipeline::MarkdownFilter
  # tbh kinda dump i had to do this.
  # for readability, removed the if statement we won't use
  def call
    extensions = context.fetch(
      :commonmarker_extensions,
      DEFAULT_COMMONMARKER_EXTENSIONS
    )
    options = [:GITHUB_PRE_LANG]
    options << :HARDBREAKS if context[:gfm] != false
    options << :UNSAFE if context[:unsafe]

    # here is where we allow options to be passed in
    options += context[:commonmarker_render_options] if context[:commonmarker_render_options]
    html = CommonMarker.render_html(@text, options, extensions)
    html.rstrip!
    html
  end
end
