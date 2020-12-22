class CreateLinks < ActiveRecord::Migration[6.0]
  def change
    create_table :links do |t|
      t.string :notebook, index: true
      t.string :identifier, index: true
      t.string :url, index: true

      t.timestamps
    end
  end
end
