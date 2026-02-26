Rails.application.routes.draw do
	# Root path
	root to: 'sessions#new'

	# Sessions
	get '/sessions', :to => 'sessions#new'
	post '/sessions', :to => 'sessions#create'

	# Locale
	get '/update_locale/:locale', :to => 'sessions#update_locale'

	# Login / logout
	get 'login', :to => 'sessions#new', :as => 'login'
	get 'logout', :to => 'sessions#destroy', :as => 'logout'
	get 'visitors_new_user', :to => 'sessions#visitors_new_user', :as => 'visitors_new_user'
	get '/sending_new_validation_mail/:id', :to => 'sessions#sending_new_validation_mail', :as => 'sending_new_validation_mail'
	get '/validate_mail/:validate_mail_token', :to => 'sessions#validate_mail', :as => 'validate_mail'

	# OmniAuth
	post 'login_facebook', to: redirect('/auth/facebook'), as: 'login_facebook'
	post 'login_google', to: redirect('/auth/google_oauth2'), as: 'login_google'
	get 'auth/:provider/callback', to: 'sessions#create'
	get 'auth/failure', to: redirect('/')

	get 'find_cep', :to => 'cep#find_cep', :as => 'find_cep'
	get '/get_card_details', :to => 'cards#get_card_details'

	delete '/destroy_attachment/:attachment_id', :to => 'users#destroy_attachment', :as => 'destroy_attachment'

	# Descomentar caso queira timeout da conexão
	# match 'active'  => 'sessions#active',  via: :get
	# match 'timeout' => 'sessions#timeout', via: :get

	# Usuários
	resources :users do
		get 'generate_contract/:user_id', :to => 'users#generate_contract', :as => 'generate_contract'
		member do
			put :block
			get :block
		end
	end
	get '/destroy_profile_image', :to => 'users#destroy_profile_image', :as => 'destroy_profile_image'
	post 'create_user', :to => 'sessions#create_user', :as => 'visitors_create_user'
	get '/send_push_test', :to => 'users#send_push_test', :as => 'send_push_test'
	post '/send_push_to_mobile', :to => 'users#send_push_to_mobile', :as => 'send_push_to_mobile'

	# Atualizar dados de acesso
	get '/change_access_data/:id', :to => 'users#change_access_data', :as => 'change_access_data'
	get '/change_data/:id', :to => 'users#change_data', :as => 'change_data'
	post '/update_access_data/:id', :to => 'users#update_access_data', :as => 'update_access_data'
	post '/reset_user_password/:id', :to => 'users#reset_user_password', :as => 'reset_user_password'

	delete 'delete_phone', :to => 'users#delete_phone', :as => 'delete_phone'
	delete 'delete_email', :to => 'users#delete_email', :as => 'delete_email'
	delete 'delete_attachment', :to => 'users#delete_attachment', :as => 'delete_attachment'
	delete 'delete_data_bank', :to => 'users#delete_data_bank', :as => 'delete_data_bank'
	delete 'delete_card', :to => 'users#delete_card', :as => 'delete_card'
	delete 'delete_address', :to => 'users#delete_address', :as => 'delete_address'
	delete 'delete_data_plan_periodicity', :to => 'users#delete_data_plan_periodicity', :as => 'delete_data_plan_periodicity'
	delete 'delete_person_contact', :to => 'users#delete_person_contact', :as => 'delete_person_contact'
	delete 'delete_sub_unit', :to => 'users#delete_sub_unit', :as => 'delete_sub_unit'
	delete 'delete_order_service_proposal_item', :to => 'users#delete_order_service_proposal_item', :as => 'delete_order_service_proposal_item'
	delete 'delete_provider_service_temp', :to => 'users#delete_provider_service_temp', :as => 'delete_provider_service_temp'
	delete 'delete_order_service_invoice', :to => 'users#delete_order_service_invoice', :as => 'delete_order_service_invoice'
	delete 'delete_addendum_contract', :to => 'users#delete_addendum_contract', :as => 'delete_addendum_contract'
	delete 'delete_cancel_commitment', :to => 'users#delete_cancel_commitment', :as => 'delete_cancel_commitment'
	delete 'delete_part_service_order_service', :to => 'users#delete_part_service_order_service', :as => 'delete_part_service_order_service'

	get 'users_admin', :to => 'users#users_admin', :as => 'users_admin'
	get 'users_user', :to => 'users#users_user', :as => 'users_user'
	get 'users_client', :to => 'users#users_client', :as => 'users_client'
	get 'users_manager', :to => 'users#users_manager', :as => 'users_manager'
	get 'users_additional', :to => 'users#users_additional', :as => 'users_additional'
	get 'users_provider', :to => 'users#users_provider', :as => 'users_provider'

	get 'validate_users', :to => 'users#validate_users', :as => 'validate_users'

	get '/approve_users', :to => 'users#approve_users', :as => 'approve_users'
	get '/disapprove_users', :to => 'users#disapprove_users', :as => 'disapprove_users'

	get '/get_managers_by_client_id', :to => 'users#managers_by_client_id'

	# Recuperar Senha
	get 'recover_pass', :to => 'users#recovery_pass', :as => 'recovery_pass'
	post 'recover_pass', :to => 'users#create_recovery_pass'
	get 'edit_pass/:recovery_token', :to => 'users#edit_pass', :as => 'edit_pass_token'
	get 'edit_pass', :to => 'users#edit_pass', :as => 'edit_pass'
	patch 'update_pass/:id', :to => 'users#update_pass', :as => 'update_pass'

	# Configurações
	resources :system_configurations, only: [:edit, :update]
	delete 'delete_gerencia_net_certificate', :to => 'system_configurations#delete_gerencia_net_certificate', :as => 'delete_gerencia_net_certificate'

	# Produtos
	resources :products

	# Ordens de compra
	resources :orders
	get '/show_order_cart', :to => 'orders#show_order_cart', :as => 'show_order_cart'
	get '/add_item_to_order', :to => 'orders#add_item_to_order', :as => 'add_item_to_order'

	delete '/remove_item_to_order/:order_cart_id', :to => 'orders#remove_item_to_order', :as => 'remove_item_to_order'
	get '/pay_order', :to => 'orders#pay_order', :as => 'pay_order'
	post '/make_payment', :to => 'orders#make_payment', :as => 'make_payment'
	post 'save_data_to_buy', :to => 'users#save_data_to_buy', :as => 'save_data_to_buy'
	post 'save_address_to_buy', :to => 'orders#save_address_to_buy', :as => 'save_address_to_buy'
	get '/check_payment/:id', :to => 'orders#check_payment', :as => 'check_payment'
	post '/generate_new_payment', :to => 'orders#generate_new_payment', :as => 'generate_new_payment'

	get '/insert_discount_coupon', :to => 'orders#insert_discount_coupon', :as => 'insert_discount_coupon'
	get '/remove_discount_coupon', :to => 'orders#remove_discount_coupon', :as => 'remove_discount_coupon'

	# Categorias
	resources :categories
	delete 'delete_sub_category', :to => 'categories#delete_sub_category', :as => 'delete_sub_category'
	get 'get_subcategories/:category_id', :to => 'categories#get_subcategories', :as => 'get_subcategories'
	# Importação
	post 'import_categories', :to => 'categories#import_categories', :as => 'import_categories'
	get 'import_model_categories', :to => 'categories#import_model_categories', :as => 'import_model_categories'
	get 'show_categories_by_category_type/:category_type_id', :to => 'categories#index', :as => 'show_categories_by_category_type'

	# Grupos de Serviço
	resources :service_groups do
		member do
			get 'services', to: 'service_groups#services'
		end
	end

	# Países
	resources :countries

	# Estados
	resources :states
	get 'countries/:country_id/states.json', :to => 'states#by_country'

	# Cidades
	resources :cities
	get 'states/:state_id/cities.json', :to => 'cities#by_state'
	get 'states/cities.json', :to => 'cities#by_state'

	# -------------------- API --------------------
	mount Api::Base => "/"
	# ------------------ FIM API ------------------

	# -------------------- CHAT --------------------
	mount ActionCable.server => '/cable'

	# Buscando mensagens antigas
	get 'get_old_messages', :to => 'messages#get_old_messages', :as => 'get_old_messages'
	get 'chat/:sender_id/:receiver_id', :to => 'rooms#show', :as => 'chat'
	# ------------------ FIM CHAT ------------------

	# Configurações do sistema (visitante)
	get 'show_text/:text_to_show', :to => 'visitors/system_configurations#show_text', :as => 'show_text'

	# Planos
	resources :plans
	delete 'delete_plan_service', :to => 'plans#delete_plan_service', :as => 'delete_plan_service'

	# FAQs
	resources :faqs

	# Banners
	resources :banners
	post 'active_banner', :to => 'banners#active_banner', :as => 'active_banner'

	# Depoimentos
	resources :testimonies

	# Contatos do site
	resources :site_contacts
	get 'new_site_contact', :to => 'visitors/site_contacts#new', :as => 'visitors_new_site_contact'
	post 'create_site_contact', :to => 'visitors/site_contacts#create', :as => 'visitors_create_site_contact'

	# Newsletter
	resources :newsletters do
		member do
			put :inactive
			get :inactive
		end
	end
	get 'new_newsletter', :to => 'visitors/newsletters#new', :as => 'visitors_new_newsletter'
	post 'create_newsletter', :to => 'visitors/newsletters#create', :as => 'visitors_create_newsletter'

	get '/services/by_category', :to => 'services#by_category', :as => 'services_by_category'
	resources :services
	get '/getting_service_values', :to => 'services#getting_service_values', :as => 'getting_service_values'
	get '/getting_service_values_new_product', :to => 'services#getting_service_values_new_product', :as => 'getting_service_values_new_product'
	
	# Importação em massa de serviços/peças
	resource :services_import, only: [:new, :create], controller: 'services_import' do
		get :template, on: :collection
	end

	# Catálogo de peças (busca nos PDFs importados)
	get '/catalogo_pecas/search', to: 'catalogo_pecas#search', as: 'catalogo_pecas_search'
	get '/catalogo_pecas/sugestoes', to: 'catalogo_pecas#sugestoes', as: 'catalogo_pecas_sugestoes'
	get '/catalogo_pecas/fornecedores', to: 'catalogo_pecas#fornecedores', as: 'catalogo_pecas_fornecedores'
	get '/catalogo_pecas/grupos', to: 'catalogo_pecas#grupos', as: 'catalogo_pecas_grupos'
	get '/catalogo_pecas/stats', to: 'catalogo_pecas#stats', as: 'catalogo_pecas_stats'

	resources :teams

	# Endereços (do usuário)
	get 'user_addresses', :to => 'users#user_addresses', :as => 'user_addresses'
	get 'new_user_address', :to => 'users#new_user_address', :as => 'new_user_address'
	get 'edit_user_address', :to => 'users#edit_user_address', :as => 'edit_user_address'
	put 'create_user_address', :to => 'users#create_user_address', :as => 'create_user_address'
	post 'update_user_address', :to => 'users#update_user_address', :as => 'update_user_address'
	delete 'destroy_user_address', :to => 'users#destroy_user_address', :as => 'destroy_user_address'

	# Cartões (do usuário)
	get 'user_cards', :to => 'users#user_cards', :as => 'user_cards'
	put 'create_user_card', :to => 'users#create_user_card', :as => 'create_user_card'
	delete 'destroy_user_card', :to => 'users#destroy_user_card', :as => 'destroy_user_card'

	# Notificação PagSeguro pagamento
	post '/notify_pix_payment', :to => 'payment_transactions#notify_pix_payment', :as => 'notify_pix_payment'
	post '/notify_change_payment', :to => 'payment_transactions#notify_change_payment', :as => 'notify_change_payment'

	# Melhor envio
	post '/melhor_envio', :to => 'melhor_envio#melhor_envio'
	get '/melhor_envio', :to => 'melhor_envio#melhor_envio'

	# Assinatura
	get '/subscriptions', :to => 'subscribe#subscriptions', :as => 'subscriptions'
	get '/subscribe', :to => 'subscribe#subscribe', :as => 'subscribe'
	get '/add_plan_to_subscribe', :to => 'subscribe#add_plan_to_subscribe', :as => 'add_plan_to_subscribe'
	get '/subscribe_plan', :to => 'subscribe#subscribe_plan', :as => 'subscribe_plan'
	post '/make_subscribe_plan', :to => 'subscribe#make_subscribe_plan', :as => 'make_subscribe_plan'
	post '/save_data_to_subscribe_plan', :to => 'subscribe#save_data_to_subscribe_plan', :as => 'save_data_to_subscribe_plan'
	post '/save_address_to_subscribe_plan', :to => 'subscribe#save_address_to_subscribe_plan', :as => 'save_address_to_subscribe_plan'
	get '/subscription', :to => 'subscribe#subscription', :as => 'subscription'
	put '/cancel_subscription', :to => 'subscribe#cancel_subscription', :as => 'cancel_subscription'
	delete '/delete_subscription', :to => 'subscribe#delete_subscription', :as => 'delete_subscription'
	get '/subscription_payment', :to => 'subscribe#subscription_payment', :as => 'subscription_payment'
	post '/generate_new_payment_subscription', :to => 'subscribe#generate_new_payment_subscription', :as => 'generate_new_payment_subscription'

	resources :blogs
	resources :discount_coupons

	post 'receive_update_d4sign', :to => 'visitors/home#receive_update_d4sign', :as => 'receive_update_d4sign'

	resources :vehicles do
		member do
			get :order_services
	end
end

resources :vehicle_models do
	member do
		get :manage_prices
		patch :update_prices
	end
end
resources :reference_prices

	resources :commitments do
		member do
			patch :inactivate
			post :save_cancel_commitment
		end
		resources :addendum_commitments, only: [:new, :create, :destroy]
	end
	get '/get_vehicles_by_cost_center_id', :to => 'vehicles#vehicles_by_cost_center_id'
	get '/get_vehicles_by_client_id', :to => 'vehicles#vehicles_by_client_id'
	get '/get_last_order_service_by_vehicle_id', :to => 'vehicles#last_order_service_by_vehicle_id'
	get '/get_commitments_by_vehicle_id', :to => 'vehicles#commitments_by_vehicle_id'
	get '/get_commitment_types_by_vehicle_id', :to => 'vehicles#commitment_types_by_vehicle_id'
	get '/get_warranty_items_by_vehicle_id', :to => 'order_services#warranty_items_by_vehicle_id'
	get '/get_client_requirements', :to => 'order_services#get_client_requirements'
	get '/get_providers_for_directed_selection', :to => 'order_services#get_providers_for_directed_selection'
	get '/getting_vehicle_by_plate_integration', :to => 'vehicles#getting_vehicle_by_plate_integration', :as => 'getting_vehicle_by_plate_integration'

  resources :vehicle_types

	resources :cost_centers
	get '/get_cost_centers_by_client_id', :to => 'cost_centers#by_client_id'
	get '/get_sub_units_by_cost_center_id', :to => 'cost_centers#sub_units_by_cost_center_id'
	get '/get_sub_units_by_client_id', :to => 'cost_centers#sub_units_by_client_id'
	get '/get_contracts_by_client_id', :to => 'contracts#by_client_id'

  resources :provider_service_types

	resources :notifications
	put '/check_all_read_notifications', :to => 'notifications#check_all_read_notifications', :as => "check_all_read_notifications"
  get 'manage_read_notification', :to => 'notifications#manage_read_notification', :as => 'manage_read_notification'

	# Relatórios Personalizados
	get 'custom_reports', :to => 'custom_reports#index', :as => 'custom_reports'

	resources :order_services
		get 'order_services/:id/print_no_values', to: 'order_services#print_no_values', as: 'print_no_values_order_service'
		get 'order_services/:id/print_os', to: 'order_services#print_os', as: 'print_os_order_service'
		get 'order_services/:id/print_os_summary', to: 'order_services#print_os_summary', as: 'print_os_summary_order_service'
	get 'show_order_services/:order_service_status_id', :to => 'order_services#show_order_services', :as => 'show_order_services'
	post 'cancel_order_service', :to => 'order_services#cancel_order_service', :as => 'cancel_order_service'
	get 'show_historic/:id', :to => 'order_services#show_historic', :as => 'show_historic'
	get 'show_invoices', :to => 'order_services#show_invoices', :as => 'show_invoices'
	get 'rejected_history', :to => 'order_services#rejected_history', :as => 'rejected_history_order_services'

	# Reavaliação e Complemento de OS
	post 'request_reevaluation/:id', :to => 'order_services#request_reevaluation', :as => 'request_reevaluation'
	post 'finish_reevaluation/:id', :to => 'order_services#finish_reevaluation', :as => 'finish_reevaluation'
	get 'new_complement/:id', :to => 'order_service_proposals#new_complement', :as => 'new_complement'
	post 'create_complement/:id', :to => 'order_service_proposals#create_complement', :as => 'create_complement'
	post 'approve_complement/:id', :to => 'order_service_proposals#approve_complement', :as => 'approve_complement'
	post 'reprove_complement/:id', :to => 'order_service_proposals#reprove_complement', :as => 'reprove_complement'

	post '/authorize_order_services', :to => 'order_services#authorize_order_services', :as => 'authorize_order_services'
	post '/waiting_payment_order_services', :to => 'order_services#waiting_payment_order_services', :as => 'waiting_payment_order_services'
	post '/make_payment_order_services', :to => 'order_services#make_payment_order_services', :as => 'make_payment_order_services'
	post '/reject_order_service', :to => 'order_services#reject_order_service', :as => 'reject_order_service'
	post '/unreject_order_service', :to => 'order_services#unreject_order_service', :as => 'unreject_order_service'
	post '/back_to_edit_order_service', :to => 'order_services#back_to_edit_order_service', :as => 'back_to_edit_order_service'

	resources :order_service_proposals
	get 'show_order_service_proposals/:order_service_proposal_status_id', :to => 'order_service_proposals#show_order_service_proposals', :as => 'show_order_service_proposals'
	get 'show_order_service_proposal/:id', :to => 'order_service_proposals#show_order_service_proposal', :as => 'show_order_service_proposal'
	get 'show_order_service_proposals_by_order_service/:order_service_id', :to => 'order_service_proposals#show_order_service_proposals_by_order_service', :as => 'show_order_service_proposals_by_order_service'
	get 'print_order_service_proposals_by_order_service/:order_service_id', :to => 'order_service_proposals#print_order_service_proposals_by_order_service', :as => 'print_order_service_proposals_by_order_service'

	post 'approve_order_service_proposal/:id', :to => 'order_service_proposals#approve_order_service_proposal', :as => 'approve_order_service_proposal'
	post 'reprove_order_service_proposal/:id', :to => 'order_service_proposals#reprove_order_service_proposal', :as => 'reprove_order_service_proposal'
	post 'refuse_additional_approval/:id', :to => 'order_service_proposals#refuse_additional_approval', :as => 'refuse_additional_approval'
	post 'refuse_additional_authorization/:id', :to => 'order_service_proposals#refuse_additional_authorization', :as => 'refuse_additional_authorization'
	post 'autorize_order_service_proposal/:id', :to => 'order_service_proposals#autorize_order_service_proposal', :as => 'autorize_order_service_proposal'
	post 'waiting_payment_order_service_proposal/:id', :to => 'order_service_proposals#waiting_payment_order_service_proposal', :as => 'waiting_payment_order_service_proposal'
	post 'paid_order_service_proposal/:id', :to => 'order_service_proposals#paid_order_service_proposal', :as => 'paid_order_service_proposal'
	post 'cancel_order_service_proposal/:id', :to => 'order_service_proposals#cancel_order_service_proposal', :as => 'cancel_order_service_proposal'
	post 'get_new_proposals_order_service_proposal/:id', :to => 'order_service_proposals#get_new_proposals_order_service_proposal', :as => 'get_new_proposals_order_service_proposal'

	post '/reprove_order_service_proposals', :to => 'order_service_proposals#reprove_order_service_proposals', :as => 'reprove_order_service_proposals'



  resources :contracts

	get 'dashboard', :to => 'order_services#dashboard', :as => 'dashboard'
	
	# Provider Dashboard
	get 'provider_dashboard', :to => 'provider_dashboard#index', :as => 'provider_dashboard'
	get 'provider_dashboard/index', :to => 'provider_dashboard#index', :as => 'provider_dashboard_index'
	get 'provider_dashboard/rejections', :to => 'provider_dashboard#rejections', :as => 'rejections_provider_dashboard'
	post 'provider_dashboard/bulk_reject', :to => 'provider_dashboard#bulk_reject', :as => 'bulk_reject_provider_dashboard'
	post 'provider_dashboard/revert_rejection', :to => 'provider_dashboard#revert_rejection', :as => 'revert_rejection_provider_dashboard'

  resources :orientation_manuals

end
