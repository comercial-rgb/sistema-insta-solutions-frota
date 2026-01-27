class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  
  include Pundit::Authorization
  # Rescue the Pundit exception and redirectos to user_not_authorized method
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protect_from_forgery with: :exception

  before_action :authenticate_user, 
  :current_user, :get_system_configuration, :set_active_storage_url_options
  
  # before_action :set_action_cable_identifier, :validate_new_order

  # Tempo para deslogar o usuário por inatividade (Descomentar caso queira o timeout)
  # auto_session_timeout 10.hour

  private
  def current_user
  	@current_user ||= User.active.where(id: session[:user_id]).first if session[:user_id]
  end

  def authenticate_user
  	if !current_user
      session[:redirect_path] = (request.base_url + request.original_fullpath)
  		redirect_to login_path
  	end
  end

  def user_not_authorized
    # TO DO defines what to do when a user have access blocked by Pundit
    redirect_to root_path, alert: t('flash.login_error')
  end

  # Buscando model de configuração do sistema
  def get_system_configuration
    @system_configuration = SystemConfiguration.first_or_create!
  end

  # Gerando um novo carrinho ou buscando o carrinho atual
  def validate_new_order
    # @order = Order.where(id: session[:order_id]).where(order_status_id: OrderStatus::EM_ABERTO_ID).first
    # if @order.nil?
    #   @order = Order.create(order_status_id: OrderStatus::EM_ABERTO_ID)
    #   session[:order_id] = @order.id
    # end
    # @order_plan = Order.where(id: session[:order_plan_id]).where(order_status_id: OrderStatus::EM_ABERTO_ID).first
    # if @order_plan.nil?
    #   @order_plan = Order.create(order_status_id: OrderStatus::EM_ABERTO_ID)
    #   session[:order_plan_id] = @order_plan.id
    # end
  end

  def set_action_cable_identifier
    cookies.encrypted[:user_id] = current_user&.id
  end

  def set_active_storage_url_options
    ActiveStorage::Current.url_options = { host: request.host, port: request.port, protocol: request.protocol }
  end
  
end
