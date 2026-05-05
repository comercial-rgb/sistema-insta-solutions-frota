# frozen_string_literal: true

class AddCategoryIdToPartServiceOrderServices < ActiveRecord::Migration[7.1]
  def up
    add_reference :part_service_order_services, :category, foreign_key: { to_table: :categories }, null: true

    execute(<<~SQL.squish)
      UPDATE part_service_order_services AS ps
      INNER JOIN services AS s ON s.id = ps.service_id
      SET ps.category_id = s.category_id
      WHERE ps.service_id IS NOT NULL AND ps.category_id IS NULL
    SQL
  end

  def down
    remove_reference :part_service_order_services, :category, foreign_key: true
  end
end
