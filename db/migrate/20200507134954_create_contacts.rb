class CreateContacts < ActiveRecord::Migration[6.0]
  def change
    create_table :contacts do |t|
      t.string :handle
      t.string :first_name
      t.string :last_name
      t.text :notes

      t.timestamps
    end
  end
end
