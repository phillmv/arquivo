class AddRemoteDetailsToNotebooks < ActiveRecord::Migration[7.0]
  def change
    add_column :notebooks, :remote, :string
    add_column :notebooks, :private_key, :text
  end
end
