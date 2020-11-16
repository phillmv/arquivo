class TodoList < ApplicationRecord
  has_many :todo_list_items, dependent: :delete_all
  belongs_to :entry
end
