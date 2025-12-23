class CreateQuotesToDestinations < ActiveRecord::Migration[7.1]
	def change
		create_table :quotes_to_destinations do |t|
			t.references :quote, foreign_key: { to_table: 'quotes' }, index: true, null: false
			t.references :destination, foreign_key: { to_table: 'destinations' }, index: true, null: false

			t.timestamps
		end
	end
end
