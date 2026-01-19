class CreateOrienationManualsProfiles < ActiveRecord::Migration[7.1]
  def change
    create_join_table :orientation_manuals, :profiles
  end
end
