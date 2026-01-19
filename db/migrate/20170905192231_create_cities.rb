class CreateCities < ActiveRecord::Migration[7.1]
	def change
		create_table :cities do |t|
			t.string :name
			t.string :latitude
			t.string :longitude
			t.string :ibge_code
			t.decimal :quantity_population
			t.references :state, index: true, foreign_key: true
			t.references :country, index: true, foreign_key: true

			t.timestamps
		end
	end
end
