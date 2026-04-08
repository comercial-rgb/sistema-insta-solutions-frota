class MaintenanceAlertService
  def self.check_for_vehicle(vehicle)
    return unless vehicle.client_id.present?

    client = vehicle.client
    plans = MaintenancePlanItem.active.where(client_id: [client.id, nil])

    plans.find_each do |plan_item|
      check_km_alert(vehicle, plan_item) if plan_item.plan_type.in?(%w[km both])
      check_days_alert(vehicle, plan_item) if plan_item.plan_type.in?(%w[days both])
    end
  end

  def self.check_all_vehicles(client_id = nil)
    scope = Vehicle.where(active: true)
    scope = scope.where(client_id: client_id) if client_id.present?

    scope.find_each do |vehicle|
      check_for_vehicle(vehicle)
    end
  end

  private

  def self.check_km_alert(vehicle, plan_item)
    return unless plan_item.km_interval.present? && plan_item.km_interval > 0

    last_km_record = VehicleKmRecord.where(vehicle_id: vehicle.id).order(created_at: :desc).first
    current_km = last_km_record&.km || 0
    return if current_km == 0

    last_service_km = vehicle.order_services
                              .where(maintenance_plan_id: plan_item.maintenance_plan_id)
                              .where.not(order_service_status_id: OrderServiceStatus::CANCELADA)
                              .order(created_at: :desc)
                              .first&.km || 0

    next_service_km = last_service_km + plan_item.km_interval
    km_remaining = next_service_km - current_km

    if km_remaining <= plan_item.km_alert_threshold
      existing = MaintenanceAlert.where(
        vehicle: vehicle,
        maintenance_plan_item: plan_item,
        alert_type: 'km',
        status: %w[pending acknowledged]
      ).exists?

      unless existing
        MaintenanceAlert.create!(
          vehicle: vehicle,
          maintenance_plan_item: plan_item,
          client_id: vehicle.client_id,
          alert_type: 'km',
          current_km: current_km,
          target_km: next_service_km,
          message: "#{plan_item.name}: manutenção necessária em #{km_remaining} km (atual: #{current_km} km, próxima: #{next_service_km} km)"
        )
      end
    end
  end

  def self.check_days_alert(vehicle, plan_item)
    return unless plan_item.days_interval.present? && plan_item.days_interval > 0

    last_service = vehicle.order_services
                           .where(maintenance_plan_id: plan_item.maintenance_plan_id)
                           .where.not(order_service_status_id: OrderServiceStatus::CANCELADA)
                           .order(created_at: :desc)
                           .first

    reference_date = last_service&.created_at&.to_date || vehicle.created_at.to_date
    next_service_date = reference_date + plan_item.days_interval.days
    days_remaining = (next_service_date - Date.current).to_i

    if days_remaining <= plan_item.days_alert_threshold
      existing = MaintenanceAlert.where(
        vehicle: vehicle,
        maintenance_plan_item: plan_item,
        alert_type: 'days',
        status: %w[pending acknowledged]
      ).exists?

      unless existing
        MaintenanceAlert.create!(
          vehicle: vehicle,
          maintenance_plan_item: plan_item,
          client_id: vehicle.client_id,
          alert_type: 'days',
          target_date: next_service_date,
          message: "#{plan_item.name}: manutenção agendada para #{next_service_date.strftime('%d/%m/%Y')} (#{days_remaining} dias restantes)"
        )
      end
    end
  end
end
