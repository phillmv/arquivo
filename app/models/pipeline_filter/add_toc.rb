# While HTML::Pipeline::TableOfContentsFilter collects headers and decorates
# them with anchors, it doesn't auto-insert them into a TOC for you.
# Here, I chose to implement <table-of-contents>, which also auto inserts an
# <h2>Contents</h2> as a header (otherwise, it'd be tricky to avoid the
# self-referencing Table of Contents without modifying TableOfContentsFilter.
#
# This filter won't work unless:
# - table-of-contents is whitelisted from tag sanitization
# - it turns *after* HTML::Pipeline::TableOfContentsFilter
class PipelineFilter::AddToc < HTML::Pipeline::Filter

  def call
    if result[:toc].present?
      toc_node = doc.css("table-of-contents").first

      if toc_node
        toc_string = "<table-of-contents><h2>Contents</h2>#{result[:toc]}</table-of-contents"
        toc_children = nil

        # if we have a well-closed tag,
        # markdown wraps it in a p
        # but lists can't be inside a paragraph
        # so let's move the toc outside the <p>
        if toc_node.parent.name == "p"
          parent_p = toc_node.parent
          toc_node.remove
          parent_p.add_next_sibling(toc_string)
        else
          toc_children = toc_node.children
          toc_node.replace(toc_string)

          if toc_children.any?
            # afaict you need to refresh the element?
            toc_node = doc.css("table-of-contents").first
            toc_node.add_next_sibling(toc_children)
          end
        end
      end
    end

    doc
  end
end
