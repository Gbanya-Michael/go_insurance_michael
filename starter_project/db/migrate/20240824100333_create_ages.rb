class CreateAges < ActiveRecord::Migration[7.1]
	def change
		create_table :ages do |t|
			t.integer :age_minimum, index: true, null: false
			t.integer :age_maximum, index: true, null: false
			t.decimal :multiplier, index: true, null: false, precision: 10, scale: 2

			t.timestamps
		end
	end
end
