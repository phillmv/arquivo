class AddImportPathToNotebooks < ActiveRecord::Migration[6.0]
  def change
    add_column :notebooks, :import_path, :string, default: nil
  end
end
