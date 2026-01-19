class CreateCategories < ActiveRecord::Migration[7.1]
	def change
		create_table :categories do |t|
			t.references :category_type, foreign_key: true
			t.string :name

			t.timestamps
		end
	end
end
