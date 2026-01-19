class CommitmentCostCenter < ApplicationRecord
  belongs_to :commitment
  belongs_to :cost_center

  validates :commitment_id, uniqueness: { scope: :cost_center_id, message: "Centro de custo já associado a este empenho" }
end
