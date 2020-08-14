class CreateKeyValues < ActiveRecord::Migration[6.0]
  def change
    create_table :key_values do |t|
      t.string :namespace
      t.string :key
      t.string :value

      t.timestamps
      t.index [:namespace, :key]
    end
  end
end
