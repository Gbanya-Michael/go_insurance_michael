class CreateQuotes < ActiveRecord::Migration[7.1]
	def change
		create_table :quotes do |t|
			t.references :trip_type, foreign_key: { to_table: 'trip_types' }, index: true, null: false
			t.integer :age, index: true, null: false
			t.date :start_date, index: true, null: false
			t.date :end_date, index: true, null: false
			t.references :excess, foreign_key: { to_table: 'excesses' }, index: true, null: false
			t.references :cover, foreign_key: { to_table: 'covers' }, index: true, null: false
			t.boolean :cruise, index: true, default: false
			t.boolean :snow, index: true, default: false
			t.date :snow_start_date, index: true, null: true
			t.date :snow_end_date, index: true, null: true

			t.timestamps
		end
	end
end
