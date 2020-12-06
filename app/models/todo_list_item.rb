class TodoListItem < ApplicationRecord
  belongs_to :todo_list
  belongs_to :entry
  has_many :tag_entries, through: :entry
  has_many :tags, through: :tag_entries
end
