class AddColourToNotebook < ActiveRecord::Migration[6.0]
  def change
    add_column :notebooks, :colour, :string, default: "#0366d6", null: false
  end
end
