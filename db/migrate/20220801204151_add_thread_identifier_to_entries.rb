class AddThreadIdentifierToEntries < ActiveRecord::Migration[6.0]
  def change
    # used as a thread key, sort of like how its used in emails
    add_column :entries, :thread_identifier, :string
  end
end
