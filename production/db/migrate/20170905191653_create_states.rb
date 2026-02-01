class CreateStates < ActiveRecord::Migration[7.1]
	def change
		create_table :states do |t|
			t.string :name
			t.string :acronym
			t.string :ibge_code
			t.references :country, index: true, foreign_key: true

			t.timestamps
		end
	end
end
