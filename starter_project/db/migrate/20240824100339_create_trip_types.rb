class CreateTripTypes < ActiveRecord::Migration[7.1]
	def change
		create_table :trip_types do |t|
			t.string :label, index: true, null: false
			t.string :trip_type, index: true, null: false
			t.decimal :multiplier, index: true, precision: 10, scale: 2

			t.timestamps
		end
	end
end
