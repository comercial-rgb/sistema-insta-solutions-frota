class CreatePersonContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :person_contacts do |t|
      t.references :ownertable, polymorphic: true, index: true
      t.string :name
      t.string :email
      t.string :phone
      t.string :office

      t.timestamps
    end
  end
end
