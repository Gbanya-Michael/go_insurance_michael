class CreateExcesses < ActiveRecord::Migration[7.1]
	def change
		create_table :excesses do |t|
			t.string :label, index: true, null: false
			t.decimal :value, index: true, null: false, precision: 10, scale: 2
			t.decimal :multiplier, index: true, precision: 10, scale: 2

			t.timestamps
		end
	end
end
