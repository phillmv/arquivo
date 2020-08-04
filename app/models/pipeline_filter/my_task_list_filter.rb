require 'task_list/filter'

# This subclass of TaskList filter works identically, except if we pass in
# the "todo_only" flag it will then kill everything in a document except for:
#
# - the first line, which usually has some hashtags for context
# - uls and lis with checkboxes in them
#
# This filter must be run after the Markdown and Sanitization filters
class PipelineFilter::MyTaskListFilter < TaskList::Filter
  TOP_LEVEL_TAGS = %w[p blockquote h1 h2 h3 h4 h5 h6 hr pre].to_set
  LIST_TAGS = ["ul", "ol"].to_set

  def call
    doc = super

    if context[:todo_only]
      # skip over first node, no matter what it is
      doc.children[1..-1].each do |node|
        name = node.name

        # kill all lists that aren't task-lists, easy
        if LIST_TAGS.include?(name)
          if node.attributes["class"]&.value != "task-list"
            node.remove
          else
            # once inside a list, remove the items that don't have a
            # checkbox in them, to provide a summarized view
            node.children.each do |list_node|
              if list_node.name == "li"
                if list_node.attributes["class"]&.value != "task-list-item"
                  list_node.remove
                end
              end
            end
          end
        elsif TOP_LEVEL_TAGS.include?(name)
          node.remove
        end
      end
    end

    doc
  end
end
