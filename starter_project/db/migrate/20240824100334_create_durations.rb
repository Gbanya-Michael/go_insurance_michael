class CreateDurations < ActiveRecord::Migration[7.1]
	def change
		create_table :durations do |t|
			t.integer :minimum_days, index: true, null: false
			t.integer :maximum_days, index: true, null: false
			t.decimal :multiplier, index: true, null: false, precision: 10, scale: 2

			t.timestamps
		end
	end
end
