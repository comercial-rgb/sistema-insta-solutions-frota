class WebhookLog < ApplicationRecord
  belongs_to :order_service

  # Status constants
  PENDING  = 0
  SUCCESS  = 1
  FAILED   = 2

  scope :pending, -> { where(status: PENDING) }
  scope :success, -> { where(status: SUCCESS) }
  scope :failed,  -> { where(status: FAILED) }
  scope :not_success, -> { where(status: [PENDING, FAILED]) }

  def pending?
    status == PENDING
  end

  def success?
    status == SUCCESS
  end

  def failed?
    status == FAILED
  end

  def status_label
    case status
    when SUCCESS then 'Enviada'
    when FAILED  then 'Falha'
    else 'Pendente'
    end
  end

  def status_badge_class
    case status
    when SUCCESS then 'bg-success'
    when FAILED  then 'bg-danger'
    else 'bg-warning text-dark'
    end
  end
end
