class CreateSyncStates < ActiveRecord::Migration[6.0]
  def change
    create_table :sync_states do |t|
      t.references :notebook, null: false, foreign_key: true
      t.string :sha

      t.timestamps
      t.index :created_at
    end
  end
end
