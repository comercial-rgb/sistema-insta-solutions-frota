class AddMobileBannerToOrientationManuals < ActiveRecord::Migration[7.0]
  def change
    add_column :orientation_manuals, :mobile_banner_enabled, :boolean, default: false, null: false
    add_column :orientation_manuals, :mobile_banner_type, :string, default: 'tip'
    add_column :orientation_manuals, :mobile_banner_title, :string
    add_column :orientation_manuals, :mobile_banner_text, :text
    add_column :orientation_manuals, :mobile_banner_order, :integer, default: 0
  end
end
