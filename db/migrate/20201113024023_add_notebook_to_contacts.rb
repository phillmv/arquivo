class AddNotebookToContacts < ActiveRecord::Migration[6.0]
  def change
    add_column :contacts, :notebook, :string, null: false, default: ""

    add_index :contacts, :notebook
    add_index :contacts, :name
  end
end
