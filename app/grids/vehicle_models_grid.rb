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
  
  column :reference_prices_count, header: 'Peças Cilia' do |record|
    record.reference_prices_count
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
