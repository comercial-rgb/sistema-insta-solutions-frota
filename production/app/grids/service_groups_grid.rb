class ServiceGroupsGrid
  include Datagrid

  scope do
    ServiceGroup.all
  end

  filter :by_id, :integer, header: proc { ServiceGroup.human_attribute_name(:id) }
  filter :by_name, :string, header: proc { ServiceGroup.human_attribute_name(:name) }
  filter :by_active, :enum, select: [[I18n.t('yes'), true], [I18n.t('no'), false]], header: proc { ServiceGroup.human_attribute_name(:active) }
  filter :by_initial_date, :date, range: false, header: proc { I18n.t('from') }
  filter :by_final_date, :date, range: false, header: proc { I18n.t('until') }

  column :id, header: proc { ServiceGroup.human_attribute_name(:id) }
  column :name, header: proc { ServiceGroup.human_attribute_name(:name) }
  column :active, header: proc { ServiceGroup.human_attribute_name(:active) } do |service_group|
    service_group.active ? I18n.t('yes') : I18n.t('no')
  end
  column :created_at, header: proc { ServiceGroup.human_attribute_name(:created_at) } do |service_group|
    CustomHelper.get_text_date(service_group.created_at, 'datetime', :full)
  end
  column :updated_at, header: proc { ServiceGroup.human_attribute_name(:updated_at) } do |service_group|
    CustomHelper.get_text_date(service_group.updated_at, 'datetime', :full)
  end

  column :actions, html: true, header: proc { ServiceGroup.human_attribute_name(:actions) } do |service_group|
    render partial: 'service_groups/datagrid_actions', locals: { record: service_group }
  end

end
