class VehicleModelsGrid
  include Datagrid

  scope do
    VehicleModel.includes(:vehicle_type).ordered
  end

  filter :vehicle_type_id, :enum, select: :vehicle_type_ids_options
  filter :brand, :string
  filter :model, :string
  filter :active, :xboolean, default: true

  column :id, html: false
  
  column :vehicle_type, order: 'vehicle_types.name' do |record|
    record.vehicle_type&.name || '-'
  end
  
  column :brand
  column :model
  column :version
  
  column :prices_count, header: 'Peças Cadastradas', order: false, html: true do |record|
    count = record.reference_prices.active.count
    if count > 0
      "<span class='badge bg-success'>#{count}</span>".html_safe
    else
      "<span class='badge bg-secondary'>0</span>".html_safe
    end
  end
  
  column :active, header: 'Status' do |record|
    record.active ? 'Ativo' : 'Inativo'
  end

  column :actions, html: true, header: 'Ações' do |record|
    render partial: 'vehicle_models/actions', locals: { record: record }
  end

  def vehicle_type_ids_options
    VehicleType.all.map { |vt| [vt.name, vt.id] }
  end
end
