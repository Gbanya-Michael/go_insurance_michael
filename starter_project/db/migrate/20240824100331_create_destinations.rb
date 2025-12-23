class CreateDestinations < ActiveRecord::Migration[7.1]
	def change
		create_table :destinations do |t|
			t.string :label, index: false, null: false
			t.string :code, index: true, null: false
			t.integer :zone, index: true, null: false
			t.decimal :multiplier, index: true, null: false
			t.decimal :ski_per_day_amount, index: true, null: false, precision: 10, scale: 2
			t.decimal :cruise_add_on_amount, index: true, null: false, precision: 10, scale: 2

			t.timestamps
		end
	end
end
