class CreateSubCategories < ActiveRecord::Migration[7.1]
	def change
		create_table :sub_categories do |t|
			t.string :name
			t.references :category, foreign_key: true

			t.timestamps
		end
	end
end
