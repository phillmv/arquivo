class ChangeContactHandleToName < ActiveRecord::Migration[6.0]
  def change
    rename_column :contacts, :handle, :name
  end
end
