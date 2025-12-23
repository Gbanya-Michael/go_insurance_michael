class CreatePremia < ActiveRecord::Migration[7.1]
	def change
		create_table :premia do |t|
			t.string :label, index: true, null: false
			t.string :premium_type, index: true, null: false
			t.decimal :multiplier, index: true, precision: 24, scale: 14

			t.timestamps
		end
	end
end
