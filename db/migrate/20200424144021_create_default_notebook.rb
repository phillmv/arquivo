class CreateDefaultNotebook < ActiveRecord::Migration[6.0]
  def up
    Notebook.create(name: "journal")
  end
end
