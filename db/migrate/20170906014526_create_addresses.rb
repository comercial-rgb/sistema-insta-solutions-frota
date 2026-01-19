class CreateAddresses < ActiveRecord::Migration[7.1]
  def change
    create_table :addresses do |t|
      t.references :ownertable, polymorphic: true, index: true
      t.string :name
      t.string :zipcode
      t.string :address
      t.string :district
      t.string :number
      t.string :complement
      t.text :reference
      t.string :latitude
      t.string :longitude
      
      t.references :address_area, index: true, foreign_key: true
      t.references :address_type, index: true, foreign_key: true
      t.references :state, index: true, foreign_key: true
      t.references :city, index: true, foreign_key: true
      t.references :country, index: true, foreign_key: true

      t.timestamps
    end
  end
end
