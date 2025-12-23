class CreateCovers < ActiveRecord::Migration[7.1]
	def change
		create_table :covers do |t|
			t.string :label, index: true, null: false
			t.string :cover_type, index: true, null: false
			t.decimal :multiplier, index: true, precision: 10, scale: 2

			t.timestamps
		end
	end
end
