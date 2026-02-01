class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :access_user
      t.string :password_digest
      t.string :recovery_token
      t.string :validate_mail_token
      t.boolean :is_blocked, default: false
      t.boolean :external_register, default: false
      t.references :profile, index: true, foreign_key: true
      t.string :phone
      t.string :cpf
      t.string :rg
      t.date :birthday

      t.references :person_type, index: true, foreign_key: true
      t.references :sex, index: true, foreign_key: true
      t.references :user_status, index: true, foreign_key: true

      t.string :social_name
      t.string :fantasy_name
      t.string :cnpj

      t.boolean :accept_therm, default: false
      t.boolean :validated_mail, default: false

      t.string :cellphone
      t.string :profession

      t.string :municipal_inscription
      t.string :state_inscription

      t.decimal :discount_percent, :precision => 15, :scale => 2

      t.string :department

      t.references :state, index: true, foreign_key: true
      t.references :city, index: true, foreign_key: true
      t.references :client, index: true, foreign_key: { to_table: :users }

      t.string :provider, limit: 50, null: false, default: ""
      t.string :uid, limit: 500, null: false, default: ""

      t.timestamps
    end
  end
end
