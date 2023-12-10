class TodoListMaker
  attr_accessor :entry

  def initialize(entry)
    @entry = entry
  end

  def make!
    task_list_items = EntryRenderer.new(entry, skip_notebook_settings: true).task_list_items


    if task_list_items
      todo_list = entry.todo_list || entry.build_todo_list

      todo_list_items = task_list_items.map { |tli|
        TodoListItem.new(
          notebook: entry.notebook,
          entry: entry,
          todo_list: todo_list,
          checked: tli.checkbox_text == "[x]",
          source: tli.source,
          updated_at: entry.updated_at,
          occurred_at: entry.occurred_at
        )
      }


      if completed?(todo_list_items)
        todo_list.completed_at ||= entry.updated_at
      end

      # there's like a way to do this non-destructively,
      # intersect the two
      todo_list.todo_list_items = todo_list_items
      todo_list.save
    else
      entry.todo_list&.destroy
    end
  end

  def completed?(task_list_items)
    task_list_items.all?(&:checked)
  end
end
