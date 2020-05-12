class CreateViewPreferences < ActiveRecord::Migration[6.0]
  def change
    create_table :view_preferences do |t|
      t.string :notebook, null: false, index: true
      t.string :identifier, index: true
      t.string :key, index: true
      t.string :value

      t.timestamps
    end
  end
end
