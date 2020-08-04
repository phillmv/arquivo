# What it says on the tin: kill everything
# in a document except for:
# - the first line, which usually has some hashtags for context
# - uls and lis with checkboxes in them
#
# This filter must be run after the Markdown, Sanitization and TaskList filters
#
# Because rn I don't love the idea of having different pipelines, in order
# for this filter to be triggered the "todo only" flag must be passed in
class PipelineFilter::OnlyTodoFilter < HTML::Pipeline::Filter
  TOP_LEVEL_TAGS = %w[p blockquote h1 h2 h3 h4 h5 h6 hr pre].to_set
  LIST_TAGS = ["ul", "ol"].to_set

  def call
    if context[:todo_only]
      doc.children[1..-1].each do |node|
        name = node.name

        if LIST_TAGS.include?(name)
          if node.attributes["class"]&.value != "task-list"
            node.remove
          end
        elsif name == "li"
          if node.attributes["class"]&.value != "task-list-item"
            node.remove
          end
        elsif TOP_LEVEL_TAGS.include?(name)
          node.remove
        end
      end
    end

    doc
  end
end
