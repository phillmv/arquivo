# Cloned from HTML::Pipeline::TableOfContentsFilter,
# but also adds support for a <table-of-contents> tag.
class PipelineFilter::TableOfContentsFilter < HTML::Pipeline::Filter
  PUNCTUATION_REGEXP = RUBY_VERSION > '1.9' ? /[^\p{Word}\- ]/u : /[^\w\- ]/

  IGNORE_PARENTS = %w(table-of-contents).to_set

  # The icon that will be placed next to an anchored rendered markdown header
  def anchor_icon
    context[:anchor_icon] || '<span aria-hidden="true" class="octicon octicon-link"></span>'
  end

  def call
    result[:toc] = String.new('')

    headers = Hash.new(0)
    doc.css('h1, h2, h3, h4, h5, h6').each do |node|
      next if has_ancestor?(node, IGNORE_PARENTS)

      text = node.text
      id = ascii_downcase(text)
      id.gsub!(PUNCTUATION_REGEXP, '') # remove punctuation
      id.tr!(' ', '-') # replace spaces with dash

      uniq = headers[id] > 0 ? "-#{headers[id]}" : ''
      headers[id] += 1
      if header_content = node.children.first
        result[:toc] << %(<li><a href="##{id}#{uniq}">#{EscapeUtils.escape_html(text)}</a></li>\n)
        header_content.add_previous_sibling(%(<a id="#{id}#{uniq}" class="anchor" href="##{id}#{uniq}" aria-hidden="true">#{anchor_icon}</a>))
      end
    end

    if result[:toc].present?
      result[:toc] = %(<ol class="table-of-contents">\n#{result[:toc]}</ol>)

      if toc_node = doc.css("table-of-contents").first

        if toc_node&.parent&.name == "p"
          parent_p = toc_node.parent
          toc_node.remove
          parent_p.add_next_sibling(toc_node)
        end

        if toc_node.children.any?
          toc_node.children.last.add_next_sibling(result[:toc])
        else
          toc_node.inner_html = "<h2>Contents</h2>\n#{result[:toc]}"
        end
      end
    end

    subject = doc.children[0..3].css("h1, h2").first

    if subject
      result[:entry_subject] = subject.text
      result[:entry_subject_html] = subject.to_s
      if context[:remove_subject]
        subject.remove
      end
    end

    doc
  end

  if RUBY_VERSION >= '2.4'
    def ascii_downcase(str)
      str.downcase(:ascii)
    end
  else
    def ascii_downcase(str)
      str.downcase
    end
  end
end
