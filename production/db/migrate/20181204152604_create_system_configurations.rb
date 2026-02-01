class CreateSystemConfigurations < ActiveRecord::Migration[7.1]
  def change
    create_table :system_configurations do |t|
      t.string :notification_mail
      t.string :contact_mail
      t.text :use_policy, :limit => 4294967295
      t.text :exchange_policy, :limit => 4294967295
      t.text :warranty_policy, :limit => 4294967295
      t.text :privacy_policy, :limit => 4294967295
      t.string :phone
      t.string :cellphone
      t.string :cnpj
      t.text :data_security_policy, :limit => 4294967295
      t.text :quality, :limit => 4294967295
      t.text :about, :limit => 4294967295
      t.text :mission, :limit => 4294967295
      t.text :view, :limit => 4294967295
      t.text :values, :limit => 4294967295
      t.string :site_link
      t.string :facebook_link
      t.string :instagram_link
      t.string :twitter_link
      t.string :youtube_link
      t.string :id_google_analytics
      t.string :page_title
      t.string :page_description

      t.integer :pix_limit_payment_minutes

      t.text :geral_conditions, :limit => 4294967295
      t.text :contract_data, :limit => 4294967295

      t.text :attendance_data, :limit => 4294967295

      t.string :about_video_link

      t.text :notification_new_users
      t.text :notification_validation_users

      t.text :about_product, :limit => 4294967295

      t.timestamps
    end
  end
end
