class TodoListItem < ApplicationRecord
  belongs_to :todo_list
  belongs_to :entry
end
