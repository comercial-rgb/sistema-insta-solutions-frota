class DataBankType < ApplicationRecord
  after_initialize :default_values

  scope :by_id, lambda { |value| where("id = ?", value) if !value.nil? && !value.blank? }

  def get_text_name
    self.id.to_s
  end

  private

  def default_values
  end

end
