class CreateOrientationManuals < ActiveRecord::Migration[7.1]
  def change
    create_table :orientation_manuals do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
