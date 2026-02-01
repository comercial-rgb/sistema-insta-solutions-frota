class ReferencePricesGrid
  include Datagrid

  scope do
    ReferencePrice.includes(:vehicle_model, :service).ordered
  end

  filter :vehicle_model_id, :enum, select: :vehicle_model_ids_options, header: 'Modelo de Veículo'
  filter :service_id, :enum, select: :service_ids_options, header: 'Peça/Serviço'
  filter :active, :xboolean, default: true

  column :id, html: false
  
  column :vehicle_model, order: 'vehicle_models.brand, vehicle_models.model' do |record|
    record.vehicle_model.display_name
  end
  
  column :service, order: 'services.name' do |record|
    record.service.name
  end
  
  column :reference_price, header: 'Preço Ref. Cilia' do |record|
    record.formatted_reference_price
  end
  
  column :max_percentage, header: '% Máx.' do |record|
    "#{record.max_percentage}%"
  end
  
  column :max_allowed_price, header: 'Valor Máx. Permitido' do |record|
    record.formatted_max_allowed_price
  end
  
  column :source, header: 'Fonte'
  
  column :active, header: 'Status' do |record|
    record.active ? 'Ativo' : 'Inativo'
  end

  column :actions, html: true, header: 'Ações' do |record|
    render partial: 'reference_prices/actions', locals: { record: record }
  end

  def vehicle_model_ids_options
    VehicleModel.active.ordered.map { |vm| [vm.display_name, vm.id] }
  end
  
  def service_ids_options
    Service.by_category_id(Category::SERVICOS_PECAS_ID).order(:name).map { |s| [s.name, s.id] }
  end
end
