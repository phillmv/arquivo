class CreateContactEmailAddresses < ActiveRecord::Migration[6.0]
  def change
    create_table :contact_email_addresses do |t|
      t.references :contact, null: false, foreign_key: true
      t.string :handle
      t.string :address
      t.string :label

      t.timestamps
    end
  end
end
