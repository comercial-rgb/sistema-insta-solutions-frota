class AddCategoryToAttachments < ActiveRecord::Migration[7.1]
  def change
    add_column :attachments, :category, :string
    add_index :attachments, :category
  end
end
