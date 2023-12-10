class AddFieldsToEntry < ActiveRecord::Migration[6.0]
  def up
    add_column :entries, :summary, :string
    add_column :entries, :identifier, :string, null: false, default: ""
    Entry.update_all("identifier = id")
    change_column :entries, :identifier, :string, default: nil
    add_index :entries, [:notebook, :identifier], unique: true

    add_column :entries, :subject, :string
    add_column :entries, :from, :string
    add_column :entries, :to, :string
    add_column :entries, :in_reply_to, :string
    add_column :entries, :state, :string

    add_column :entries, :hide, :boolean, null: false, default: false, index: true

    change_column_null :entries, :identifier, true
  end

  def down
    remove_index :entries, [:notebook, :identifier]
    remove_column :entries, :summary, :string
    remove_column :entries, :identifier, :string
    remove_column :entries, :subject, :string
    remove_column :entries, :from, :string
    remove_column :entries, :to, :string
    remove_column :entries, :hide, :boolean
    remove_column :entries, :in_reply_to
    remove_column :entries, :state
  end
end
