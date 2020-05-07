class CreateCalendarImports < ActiveRecord::Migration[6.0]
  def change
    create_table :calendar_imports do |t|
      t.string :notebook, null: false, index: true
      t.string :title
      t.string :url, null: false
      t.datetime :last_ran_at

      t.timestamps
    end
  end
end
