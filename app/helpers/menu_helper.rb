module MenuHelper

	def get_complete_menu(current_user)
		menu_links = []

		users_links = get_users_menu
		if current_user.admin? || current_user.manager? || current_user.additional?
			order_services_links = get_order_services_menu_admin(current_user)
		elsif current_user.provider?
			order_services_links = get_order_services_menu_provider(current_user)
		end
		menu_links.push(users_links)

		# Dashboard do Fornecedor (apenas para fornecedores)
		if current_user.provider?
			menu_links.push({
				opened: is_current_controller?("provider_dashboard"),
				icon: "bi bi-speedometer2",
				label: "Dashboard",
				href: provider_dashboard_path
			})
		end

		if policy(User).users_client?
			# Clientes
			menu_links.push({
				opened: is_menu_users_client_opened?,
				icon: "bi bi-three-dots-vertical",
				label: User.human_attribute_name(:client_users),
				href: users_client_path
			})
		end

		menu_links.push(order_services_links)

		if policy(OrderService).index?
			# Ordens de serviços
			menu_links.push({
				opened: (is_current_controller?("order_services") && !action?('show_order_services') && !action?('show_invoices') && !action?('dashboard')),
				icon: "bi bi-three-dots-vertical",
				label: OrderService.human_attribute_name(:reports),
				href: order_services_path
			})
		end

		if policy(OrderService).dashboard?
			# Faturas
			menu_links.push({
				opened: action?('dashboard'),
				icon: "bi bi-three-dots-vertical",
				label: OrderService.human_attribute_name(:dashboard),
				href: dashboard_path
			})
		end

		if policy(OrderService).show_invoices?
			# Faturas
			menu_links.push({
				opened: action?('show_invoices'),
				icon: "bi bi-three-dots-vertical",
				label: OrderService.human_attribute_name(:show_invoices),
				href: show_invoices_path
			})
		end

		if policy(:custom_report).index?
			# Relatórios Personalizados
			menu_links.push({
				opened: is_current_controller?("custom_reports"),
				icon: "bi bi-file-earmark-bar-graph",
				label: "Relatórios Personalizados",
				href: custom_reports_path
			})
		end

		if policy(ProviderServiceType).index?
			# Tipos de serviços de fornecedor
			menu_links.push({
				opened: is_current_controller?("provider_service_types"),
				icon: "bi bi-three-dots-vertical",
				label: ProviderServiceType.model_name.human(count: 2),
				href: provider_service_types_path
			})
		end

		if policy(Contract).index?
			# Contratos
			menu_links.push({
				opened: is_current_controller?("contracts"),
				icon: "bi bi-three-dots-vertical",
				label: Contract.model_name.human(count: 2),
				href: contracts_path
			})
		end

		if policy(CostCenter).index?
			# Centros de custo
			menu_links.push({
				opened: is_current_controller?("cost_centers"),
				icon: "bi bi-three-dots-vertical",
				label: CostCenter.model_name.human(count: 2),
				href: cost_centers_path
			})
		end

		if policy(Commitment).index?
			# Empenhos
			menu_links.push({
				opened: is_current_controller?("commitments"),
				icon: "bi bi-three-dots-vertical",
				label: Commitment.model_name.human(count: 2),
				href: commitments_path
			})
		end

		if current_user.admin?
			# Grupos de Serviço
			menu_links.push({
				opened: is_current_controller?("service_groups"),
				icon: "bi bi-three-dots-vertical",
				label: ServiceGroup.model_name.human(count: 2),
				href: service_groups_path
			})
		end

		if policy(Vehicle).index?
			# Veículos
			menu_links.push({
				opened: is_current_controller?("vehicles"),
				icon: "bi bi-three-dots-vertical",
				label: Vehicle.model_name.human(count: 2),
				href: vehicles_path
			})
		end

		if policy(VehicleModel).index?
			# Modelos de Veículos
			menu_links.push({
				opened: is_current_controller?("vehicle_models"),
				icon: "bi bi-car-front",
				label: "Modelos de Veículos",
				href: vehicle_models_path
			})
		end

		if policy(ReferencePrice).index?
			# Preços de Referência
			menu_links.push({
				opened: is_current_controller?("reference_prices"),
				icon: "bi bi-currency-dollar",
				label: "Preços de Referência",
				href: reference_prices_path
			})
		end

		if policy(Service).index?
			# Produtos/serviços
			menu_links.push({
				opened: is_current_controller?("services"),
				icon: "bi bi-three-dots-vertical",
				label: Service.model_name.human(count: 2),
				href: services_path
			})
		end

		if policy(VehicleType).index?
			# Tipos de veículos
			menu_links.push({
				opened: is_current_controller?("vehicle_types"),
				icon: "bi bi-three-dots-vertical",
				label: VehicleType.model_name.human(count: 2),
				href: vehicle_types_path
			})
		end

		if policy(Category).index?
			# Categorias de serviços
			menu_links.push({
				opened: is_menu_categories_vehicle_opened?,
				icon: "bi bi-three-dots-vertical",
				label: Category.human_attribute_name(:vehicles),
				href: categories_path(category_type_id: CategoryType::VEICULOS_ID)
			})
		end

		if policy(Notification).index_by_menu?
			# Tipos de veículos
			menu_links.push({
				opened: is_current_controller?("notifications"),
				icon: "bi bi-three-dots-vertical",
				label: Notification.model_name.human(count: 2),
				href: notifications_path
			})
		end

		if policy(OrientationManual).index?
			# Manuais de orientação
			menu_links.push({
				opened: is_current_controller?("orientation_manuals"),
				icon: "bi bi-three-dots-vertical",
				# icon: "bi bi-journal-bookmark",
				label: OrientationManual.model_name.human(count: 2),
				href: orientation_manuals_path
			})
		end

		return menu_links
	end

	# Menu de usuários
	def get_users_menu
		result = {}
		submenus = []
		if policy(User).users_admin?
			# Administradores
			submenus.push({
				opened: is_menu_users_admin_opened?,
				label: User.human_attribute_name(:admin_users),
				href: users_admin_path
			})
		end
		if policy(User).users_manager?
			# Gestores
			submenus.push({
				opened: is_menu_users_manager_opened?,
				label: User.human_attribute_name(:manager_users),
				href: users_manager_path
			})
		end
		if policy(User).users_additional?
			# Adicionais
			submenus.push({
				opened: is_menu_users_additional_opened?,
				label: User.human_attribute_name(:additional_users),
				href: users_additional_path
			})
		end
		if policy(User).users_provider?
			# Fornecedores
			submenus.push({
				opened: is_menu_users_provider_opened?,
				label: User.human_attribute_name(:provider_users),
				href: users_provider_path
			})
		end
		if submenus.length > 0
			result = {
				opened: is_menu_users_opened?,
				icon: "bi bi-people",
				label: User.human_attribute_name(:users),
				submenus: submenus
			}
		end
		return result
	end

	# Lista de status de OS com ordenação única para todos os perfis
	def build_order_service_status_submenus(current_user)
		OrderServiceStatus.menu_ordered.where.not(id: OrderServiceStatus::EM_CADASTRO_ID).map do |order_service_status|
			# Para admin/gestor/adicional, a aba APROVADA não deve contar OS que possuem complemento pendente
			# (essas ficam no pseudo-status "Aguardando Aprovação de Complemento").
			if (current_user.admin? || current_user.manager? || current_user.additional?) && order_service_status.id.to_i == OrderServiceStatus::APROVADA_ID
				base_scope = OrderService.unscoped
				if current_user.manager? || current_user.additional?
					client_id = current_user.client_id
					cost_center_ids = current_user.associated_cost_centers.map(&:id)
					sub_unit_ids = current_user.associated_sub_units.map(&:id)
					base_scope = base_scope.by_client_id(client_id).by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
				end

				excluded_ids = base_scope
					.where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
					.joins(:order_service_proposals)
					.where(order_service_proposals: {
						is_complement: true,
						order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
					})
					.select(:id)

				quantity = base_scope
					.where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
					.where.not(id: excluded_ids)
					.distinct
					.count(:id)
			else
				quantity = OrderService.getting_total_order_services_by_status(current_user, order_service_status.id)
			end
			{
				opened: is_menu_order_services_status_opened?(order_service_status.id),
				label: order_service_status.name+" ("+quantity.to_s+")",
				href: show_order_services_path(order_service_status_id: order_service_status.id)
			}
		end
	end

	# Menu de ordens de serviço (administrador, gerente e adicional)
	def get_order_services_menu_admin(current_user)
		result = {}
		submenus = []

		# 1. Em cadastro no TOPO (status de propostas Em cadastro)
		proposal_status = OrderServiceProposalStatus.find_by(id: OrderServiceProposalStatus::EM_CADASTRO_ID)
		if proposal_status
			quantity = OrderServiceProposal.getting_total_order_services_proposal_by_status(current_user, OrderServiceProposalStatus::EM_CADASTRO_ID)
			submenus.push({
				opened: is_menu_order_services_proposal_status_opened?(OrderServiceProposalStatus::EM_CADASTRO_ID),
				label: proposal_status.name+" ("+quantity.to_s+")",
				href: show_order_service_proposals_path(order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID)
			})
		end

		# 2. Status de OS ordenados, inserindo "Aguardando aprovação de complemento" após Aprovada
		OrderServiceStatus.menu_ordered.where.not(id: OrderServiceStatus::EM_CADASTRO_ID).each do |order_service_status|
			# Para admin/gestor/adicional, a aba APROVADA não deve contar OS que possuem complemento pendente
			# (essas ficam no pseudo-status "Aguardando Aprovação de Complemento").
			if (current_user.admin? || current_user.manager? || current_user.additional?) && order_service_status.id.to_i == OrderServiceStatus::APROVADA_ID
				base_scope = OrderService.unscoped
				if current_user.manager? || current_user.additional?
					client_id = current_user.client_id
					cost_center_ids = current_user.associated_cost_centers.map(&:id)
					sub_unit_ids = current_user.associated_sub_units.map(&:id)
					base_scope = base_scope.by_client_id(client_id).by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
				end

				excluded_ids = base_scope
					.where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
					.joins(:order_service_proposals)
					.where(order_service_proposals: {
						is_complement: true,
						order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
					})
					.select(:id)

				quantity = base_scope
					.where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
					.where.not(id: excluded_ids)
					.distinct
					.count(:id)
			else
				quantity = OrderService.getting_total_order_services_by_status(current_user, order_service_status.id)
			end
			
			submenus.push({
				opened: is_menu_order_services_status_opened?(order_service_status.id),
				label: order_service_status.name+" ("+quantity.to_s+")",
				href: show_order_services_path(order_service_status_id: order_service_status.id)
			})
			
			# 3. Inserir "Aguardando aprovação de complemento" logo APÓS Aprovada
			if order_service_status.id.to_i == OrderServiceStatus::APROVADA_ID
				complement_status = OrderServiceProposalStatus.find_by(id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID)
				if complement_status
					complement_quantity = OrderService.getting_total_order_services_by_status(current_user, 'aguardando_complemento')
					submenus.push({
						opened: is_menu_order_services_status_opened?('aguardando_complemento'),
						label: complement_status.name+" ("+complement_quantity.to_s+")",
						href: show_order_services_path(order_service_status_id: 'aguardando_complemento')
					})
				end
			end
		end
		
		# 4. Rejeições no final
		quantity = OrderService.getting_total_order_services_by_status(current_user, OrderServiceStatus::TEMP_REJEITADA_ID)
		submenus.push({
			opened: is_menu_order_services_status_opened?(OrderServiceStatus::TEMP_REJEITADA_ID),
			label: OrderService.human_attribute_name(:rejecteds)+" ("+quantity.to_s+")",
			href: show_order_services_path(order_service_status_id: OrderServiceStatus::TEMP_REJEITADA_ID)
		})
		if submenus.length > 0
			result = {
				opened: is_menu_order_services_opened?,
				icon: "bi bi-card-list",
				label: OrderService.model_name.human(count: 2),
				submenus: submenus
			}
		end
		return result
	end

	# Menu de ordens de serviço fornecedor
	def get_order_services_menu_provider(current_user)
		result = {}
		submenus = []

		# Primeiro: Em cadastro (proposta)
		em_cadastro_status = OrderServiceProposalStatus.find_by(id: OrderServiceProposalStatus::EM_CADASTRO_ID)
		if em_cadastro_status
			quantity = OrderServiceProposal.getting_total_order_services_proposal_by_status(current_user, OrderServiceProposalStatus::EM_CADASTRO_ID)
			submenus.push({
				opened: is_menu_order_services_proposal_status_opened?(OrderServiceProposalStatus::EM_CADASTRO_ID),
				label: em_cadastro_status.name+" ("+quantity.to_s+")",
				href: show_order_service_proposals_path(order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID)
			})
		end

		# Status de OS específicos para fornecedores
		# Em aberto, Em reavaliação, Cancelada
		[OrderServiceStatus::EM_ABERTO_ID, OrderServiceStatus::EM_REAVALIACAO_ID, OrderServiceStatus::CANCELADA_ID].each do |status_id|
			os_status = OrderServiceStatus.find_by(id: status_id)
			next unless os_status
			quantity = OrderService.getting_total_order_services_by_status(current_user, status_id)
			submenus.push({
				opened: is_menu_order_services_status_opened?(status_id),
				label: os_status.name+" ("+quantity.to_s+")",
				href: show_order_services_path(order_service_status_id: status_id)
			})
		end

		# Restante dos status de propostas do fornecedor
		# Ordem: Aguardando avaliação, Aprovada, Aguardando aprovação complemento, ...resto
		provider_status_order = [
			OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID,
			OrderServiceProposalStatus::APROVADA_ID,
			OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID,
			OrderServiceProposalStatus::NOTAS_INSERIDAS_ID,
			OrderServiceProposalStatus::AUTORIZADA_ID,
			OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
			OrderServiceProposalStatus::PAGA_ID
		]
		
		provider_status_order.each do |status_id|
			order_service_proposal_status = OrderServiceProposalStatus.find_by(id: status_id)
			next unless order_service_proposal_status
			
			quantity = OrderServiceProposal.getting_total_order_services_proposal_by_status(current_user, order_service_proposal_status.id)
			submenus.push({
				opened: is_menu_order_services_proposal_status_opened?(order_service_proposal_status.id),
				label: order_service_proposal_status.name+" ("+quantity.to_s+")",
				href: show_order_service_proposals_path(order_service_proposal_status_id: order_service_proposal_status.id)
			})
		end

		quantity = current_user.rejected_order_services.length
		submenus.push({
			opened: is_menu_order_services_status_opened?(OrderServiceStatus::TEMP_REJEITADA_ID),
			label: OrderService.human_attribute_name(:rejecteds)+" ("+quantity.to_s+")",
			href: show_order_services_path(order_service_status_id: OrderServiceStatus::TEMP_REJEITADA_ID)
		})

		if submenus.length > 0
			result = {
				opened: is_menu_order_services_proposal_opened?,
				icon: "bi bi-card-list",
				label: OrderService.model_name.human(count: 2),
				submenus: submenus
			}
		end
		return result
	end

	# Menu de endereços
	def get_addresses_menu
		result = {}
		submenus = []
		if policy(Country).index?
			# Países
			submenus.push({
				opened: is_current_controller?("countries"),
				label: Country.model_name.human(count: 2),
				href: countries_path
			})
		end
		if policy(State).index?
			# Estados
			submenus.push({
				opened: is_current_controller?("states"),
				label: State.model_name.human(count: 2),
				href: states_path
			})
		end
		if policy(City).index?
			# Cidades
			submenus.push({
				opened: is_current_controller?("cities"),
				label: City.model_name.human(count: 2),
				href: cities_path
			})
		end
		if submenus.length > 0
			result = {
				icon: "bi bi-list",
				label: t("menu.address"),
				submenus: submenus
			}
		end
		return result
	end

	# Menu de categorias
	def get_categories_menu
		result = {}
		if policy(Category).index?
			submenus = []
			# Categorias de planos
			submenus.push({
				opened: is_menu_categories_plan_opened?,
				label: Category.human_attribute_name(:plans),
				href: categories_path(category_type_id: CategoryType::PLANOS_ID)
			})
			# Categorias de produtos
			submenus.push({
				opened: is_menu_categories_product_opened?,
				label: Category.human_attribute_name(:products),
				href: categories_path(category_type_id: CategoryType::PRODUTOS_ID)
			})
			# Categorias de serviços
			submenus.push({
				opened: is_menu_categories_service_opened?,
				label: Category.human_attribute_name(:services),
				href: categories_path(category_type_id: CategoryType::SERVICOS_ID)
			})
			result = {
				opened: is_menu_categories_opened?,
				icon: "bi bi-layers",
				label: t("menu.categories"),
				submenus: submenus
			}
		end
		return result
	end

	def is_current_controller?(controller)
		current_controller = current_controller_name
		return current_controller == controller
	end

	def is_current_action?(action)
		current_action = current_action_name
		return current_action == action
	end

	def is_menu_users_opened?
		return is_menu_users_to_validate_opened? || is_menu_users_admin_opened? || is_menu_users_user_opened? || is_menu_users_manager_opened? || is_menu_users_additional_opened? || is_menu_users_provider_opened?
	end

	def is_menu_order_services_opened?
		result = false
		OrderServiceStatus.all.each do |order_service_status|
			if is_menu_order_services_status_opened?(order_service_status.id)
				result = true
				break
			end
		end
		if !result
			result = is_menu_order_services_status_opened?(OrderServiceStatus::TEMP_REJEITADA_ID)
		end
		return result
	end

	def is_menu_order_services_proposal_opened?
		result = false
		OrderServiceProposalStatus.all.each do |order_service_proposal_status|
			if is_menu_order_services_proposal_status_opened?(order_service_proposal_status.id)
				result = true
				break
			end
		end
		if !result
			result = is_menu_order_services_status_opened?(OrderServiceStatus::EM_ABERTO_ID)
		end
		if !result
			result = is_menu_order_services_status_opened?(OrderServiceStatus::TEMP_REJEITADA_ID)
		end
		if !result
			result = is_current_controller?('order_service_proposals') && (is_current_action?('new') || is_current_action?('create'))
		end
		return result
	end

	def is_menu_order_services_status_opened?(order_service_status_id)
		result = false
		if contains_current_page?("/show_order_services/"+order_service_status_id.to_s) || (!@order_service.nil? && @order_service.order_service_status_id == order_service_status_id)
			result = true
		end
		return result
	end

	def is_menu_order_services_proposal_status_opened?(order_service_proposal_status_id)
		result = false
		if (contains_current_page?("/show_order_service_proposals/"+order_service_proposal_status_id.to_s) || (!@order_service_proposal.nil? && @order_service_proposal.order_service_proposal_status_id == order_service_proposal_status_id))
			result = true
		end
		return result
	end

	def is_menu_users_to_validate_opened?
		result = false
		if is_current_controller?('users')
			if is_current_action?("validate_users")
				result = true
			end
		end
		return result
	end

	def is_menu_users_admin_opened?
		result = false
		if is_current_controller?('users')
			if (is_current_action?("users_admin") || (!@user.nil? && @user.profile_id == Profile::ADMIN_ID))
				result = true
			end
		end
		return result
	end

	def is_menu_users_user_opened?
		result = false
		if is_current_controller?('users')
			if (is_current_action?("users_user") || (!@user.nil? && @user.profile_id == Profile::USER_ID))
				result = true
			end
		end
		return result
	end

	def is_menu_users_client_opened?
		result = false
		if is_current_controller?('users')
			if (is_current_action?("users_client") || (!@user.nil? && @user.profile_id == Profile::CLIENT_ID))
				result = true
			end
		end
		return result
	end

	def is_menu_users_manager_opened?
		result = false
		if is_current_controller?('users')
			if (is_current_action?("users_manager") || (!@user.nil? && @user.profile_id == Profile::MANAGER_ID))
				result = true
			end
		end
		return result
	end

	def is_menu_users_additional_opened?
		result = false
		if is_current_controller?('users')
			if (is_current_action?("users_additional") || (!@user.nil? && @user.profile_id == Profile::ADDITIONAL_ID))
				result = true
			end
		end
		return result
	end

	def is_menu_users_provider_opened?
		result = false
		if is_current_controller?('users')
			if (is_current_action?("users_provider") || (!@user.nil? && @user.profile_id == Profile::PROVIDER_ID))
				result = true
			end
		end
		return result
	end

	def is_menu_categories_opened?
		return is_menu_categories_plan_opened? || is_menu_categories_product_opened? || is_menu_categories_service_opened? || is_menu_categories_vehicle_opened
	end

	def is_menu_categories_plan_opened?
		result = false
		if is_current_controller?('categories')
			if ((is_current_action?("index") && params[:category_type_id].to_i == CategoryType::PLANOS_ID) || (!@category.nil? && @category.category_type_id == CategoryType::PLANOS_ID))
				result = true
			end
		end
		return result
	end

	def is_menu_categories_product_opened?
		result = false
		if is_current_controller?('categories')
			if ((is_current_action?("index") && params[:category_type_id].to_i == CategoryType::PRODUTOS_ID) || (!@category.nil? && @category.category_type_id == CategoryType::PRODUTOS_ID))
				result = true
			end
		end
		return result
	end

	def is_menu_categories_service_opened?
		result = false
		if is_current_controller?('categories')
			if ((is_current_action?("index") && params[:category_type_id].to_i == CategoryType::SERVICOS_ID) || (!@category.nil? && @category.category_type_id == CategoryType::SERVICOS_ID))
				result = true
			end
		end
		return result
	end

	def is_menu_categories_vehicle_opened?
		result = false
		if is_current_controller?('categories')
			if ((is_current_action?("index") && params[:category_type_id].to_i == CategoryType::VEICULOS_ID) || (!@category.nil? && @category.category_type_id == CategoryType::VEICULOS_ID))
				result = true
			end
		end
		return result
	end

end
