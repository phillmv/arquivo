class CreateFeatureFlags < ActiveRecord::Migration[6.0]
  def change
    create_table :feature_flags do |t|
      t.string :name, index: true
      t.boolean :active, default: false

      t.timestamps
    end
  end
end
