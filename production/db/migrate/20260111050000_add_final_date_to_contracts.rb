class AddFinalDateToContracts < ActiveRecord::Migration[7.1]
  def change
    add_column :contracts, :final_date, :string
    add_column :contracts, :expiration_notified_at, :datetime
  end
end
