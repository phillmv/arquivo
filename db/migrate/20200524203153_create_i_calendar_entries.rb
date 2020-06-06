class CreateICalendarEntries < ActiveRecord::Migration[6.0]
  def change
    create_table :i_calendar_entries do |t|
      t.references :calendar_import, null: false, foreign_key: true
      t.string :name
      t.string :uid
      t.datetime :recurrence_id
      t.string :sequence
      t.date :start_date
      t.date :end_date
      t.datetime :start_time
      t.datetime :end_time
      t.boolean :recurs
      t.text :body

      t.timestamps
    end
  end
end
