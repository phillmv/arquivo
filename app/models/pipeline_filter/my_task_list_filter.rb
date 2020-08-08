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

  def handle_list_contents(node)
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
  end

  def is_a_list?(node)
    LIST_TAGS.include?(node.name)
  end

  def is_a_list_item?(node)
    node.name == "li"
  end

  def is_a_task_list?(node)
    node.attributes["class"]&.value == "task-list"
  end

  def is_a_task_list_item?(node)
    node.attributes["class"]&.value == "task-list-item"
  end


  def call
    doc = super

    if context[:todo_only]
      # skip over first node, no matter what it is
      doc.children[1..-1].each do |node|
        if is_a_list?(node)
          list = node

          if is_a_task_list?(list)
            list.children.each do |li|
              if !is_a_task_list_item?(li)
                li.remove
              end
            end
          else
            # wait, are any of its grandchildren a tasklist?
            mark_for_deletion = []
            delete_list = true

            # TODO: make recursive????
            list.children.each do |li|
              delete_li = true

              li.children.each do |li_node|
                if is_a_list?(li_node) && is_a_task_list?(li_node)
                  delete_li = false
                end
              end

              # no list, delete this item
              if delete_li
                mark_for_deletion << li
              else
                # yes list, don't delete the whole list
                delete_list = false
              end
            end

            if delete_list
              list.remove
            else
              mark_for_deletion.each(&:remove)
            end
          end
        elsif TOP_LEVEL_TAGS.include?(node.name)
          node.remove
        end
      end
    end

    doc
  end
end
