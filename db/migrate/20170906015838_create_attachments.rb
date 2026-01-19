class CreateAttachments < ActiveRecord::Migration[7.1]
	def change
		create_table :attachments do |t|
			t.references :ownertable, polymorphic: true, index: true
			t.integer :attachment_type

			t.timestamps
		end
	end
end
