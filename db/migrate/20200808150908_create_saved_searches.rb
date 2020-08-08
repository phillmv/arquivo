class CreateSavedSearches < ActiveRecord::Migration[6.0]
  def change
    create_table :saved_searches do |t|
      t.string :notebook, index: true, null: false
      t.string :octicon
      t.string :name, null: false
      t.string :query, null: false

      t.timestamps
    end
  end
end
