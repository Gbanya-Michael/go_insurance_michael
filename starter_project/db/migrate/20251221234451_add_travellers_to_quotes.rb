class AddTravellersToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :travellers, :json, default: []
  end
end
