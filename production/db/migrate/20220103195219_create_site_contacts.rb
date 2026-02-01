class CreateSiteContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :site_contacts do |t|
      t.references :site_contact_subject, foreign_key: true, index: true
      t.string :name
      t.string :email
      t.string :phone
      t.text :message, :limit => 42949672
      t.references :user, foreign_key: true, index: true

      t.timestamps
    end
  end
end
