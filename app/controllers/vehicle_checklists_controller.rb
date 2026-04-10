class VehicleChecklistsController < ApplicationController
  before_action :set_checklist, only: [:show, :acknowledge, :create_os]

  def show
    authorize @checklist, :show?
    @vehicle = @checklist.vehicle
  end

  def acknowledge
    authorize @checklist, :acknowledge?
    @checklist.acknowledge!(@current_user)
    redirect_back fallback_location: vehicle_checklist_path(@checklist), notice: 'Ciência registrada com sucesso!'
  end

  def create_os
    authorize @checklist, :create_os?
    @vehicle = @checklist.vehicle

    order_service = OrderService.new(
      vehicle_id: @vehicle.id,
      client_id: @checklist.client_id,
      cost_center_id: @checklist.cost_center_id,
      user_id: @current_user.id,
      description: build_os_description(@checklist),
      order_service_status_id: OrderServiceStatus::EM_ABERTO_ID
    )

    if order_service.save
      @checklist.create_os_from_checklist!(order_service)
      redirect_to edit_order_service_path(order_service), notice: 'OS criada a partir do checklist com sucesso!'
    else
      redirect_to vehicle_checklist_path(@checklist), alert: 'Erro ao criar OS: ' + order_service.errors.full_messages.join(', ')
    end
  end

  private

  def set_checklist
    @checklist = VehicleChecklist.find(params[:id])
  end

  def build_os_description(checklist)
    lines = ["Checklist veicular ##{checklist.id} - #{checklist.created_at.strftime('%d/%m/%Y %H:%M')}"]
    lines << "KM: #{checklist.current_km}" if checklist.current_km.present?
    lines << ""

    checklist.items.where(has_anomaly: true).each do |item|
      lines << "• [#{item.category.upcase}] #{item.item_name} - #{item.condition}"
      lines << "  Obs: #{item.observation}" if item.observation.present?
    end

    lines << ""
    lines << "Notas gerais: #{checklist.general_notes}" if checklist.general_notes.present?
    lines.join("\n")
  end
end
