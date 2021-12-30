class RecreateLinksTable < ActiveRecord::Migration[6.0]
  def up
    drop_table :links

    create_table :links do |t|
      t.references :notebook, index: true, null: false
      t.string :identifier, index: true, null: false
      t.string :url, index: true, null: false

      t.timestamps
    end
  end
end
