class SubscribeController < ApplicationController
  before_action :set_subscription, only: [:subscription, :cancel_subscription, :delete_subscription, :subscription_payment, :generate_new_payment_subscription]

  skip_before_action :authenticate_user, only: [:subscribe, :add_plan_to_subscribe, :subscribe_plan]

  def subscriptions
    authorize Subscription
    if params[:subscriptions_grid].nil? || params[:subscriptions_grid].blank?
      @subscriptions = SubscriptionsGrid.new(:current_user => @current_user)
      @subscriptions_to_export = SubscriptionsGrid.new(:current_user => @current_user)
    else
      @subscriptions = SubscriptionsGrid.new(params[:subscriptions_grid].merge(current_user: @current_user))
      @subscriptions_to_export = SubscriptionsGrid.new(params[:subscriptions_grid].merge(current_user: @current_user))
    end

    if @current_user.admin?
      @subscriptions.scope {|scope| scope.page(params[:page]) }
    elsif @current_user.user?
      @subscriptions.scope {|scope| scope.where(user_id: @current_user.id).page(params[:page]) }
      @subscriptions_to_export.scope {|scope| scope.where(user_id: @current_user.id)}
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @subscriptions_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"), 
        type: "text/csv", 
        disposition: 'inline', 
        filename: Subscription.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def subscribe
    authorize Subscription
    if params[:plans_subscribe_grid].nil? || params[:plans_subscribe_grid].blank?
      @plans = PlansSubscribeGrid.new(:current_user => @current_user)
      @plans_to_export = PlansSubscribeGrid.new(:current_user => @current_user)
    else
      @plans = PlansSubscribeGrid.new(params[:plans_subscribe_grid].merge(current_user: @current_user))
      @plans_to_export = PlansSubscribeGrid.new(params[:plans_subscribe_grid].merge(current_user: @current_user))
    end

    @plans.scope {|scope| scope.page(params[:page]) }

    respond_to do |format|
      format.html
      format.csv do
        send_data @plans_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"), 
        type: "text/csv", 
        disposition: 'inline', 
        filename: Plan.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def add_plan_to_subscribe
    result = Subscription.add_plan_to_order(@order_plan, params[:plan_id], params[:data_plan_periodicity_id])
    if !result[0]
      flash[:error] = result[1]
    end
    redirect_to subscribe_plan_path
  end
  
  def subscribe_plan
    @current_order = @order_plan
    @current_order.save!
    plan = @current_order.getting_plan_object
    data_plan_periodicity = @current_order.getting_data_plan_periodicity_object

    if plan.nil? || data_plan_periodicity.nil?
      redirect_to subscribe_path
    else
      if @current_user.nil?
        session[:current_plan_subscribe] = @current_order.id
        redirect_to login_path
      else
        @current_order.update_columns(user_id: @current_user.id)
        authorize @current_order
        @current_user.skip_validate_password = true
        if !@current_user.valid?
          flash[:error] = @current_user.errors.full_messages.join('<br>')
          redirect_to change_data_path(id: @current_user.id)
        else
          @current_order.update_columns(user_id: @current_user.id)
          @current_order = build_initial_relations(@current_order)
        end
      end
    end

  end

  def build_initial_relations(current_order)
    current_order.card.destroy if !current_order.card.nil?
    current_order.build_card if current_order.card.nil?
    current_order.build_address if current_order.address.nil?
    return current_order
  end

  def make_subscribe_plan
    @current_order = @order_plan
    
    @current_order.update(order_params)
    Order.validate_card_payment(@current_order, order_params[:card_attributes], order_params[:card_id])
    @current_order.reload
    service = Utils::PaymentService.new(PaymentTransaction::GATEWAY_PAGSEGURO, @current_order, @current_user, @system_configuration, nil, nil, nil, false)
    transaction = service.call

    if transaction[0]
      if transaction[1]
        flash[:success] = transaction[2]
        subscription = Subscription.making_subscription(@current_order)
        if !subscription.nil?
          if @current_order.payment_type_id == PaymentType::CARTAO_CREDITO_ID
            redirect_to subscriptions_path
          else
            redirect_to subscription_payment_path(id: subscription.id, order_id: @current_order.id)
          end
        else
          redirect_to change_data_path(id: @current_user.id)
        end
      else
        flash[:error] = transaction[2]
        redirect_to subscribe_plan_path(id: @current_order)
      end
    else
      flash[:error] = transaction[2]
      redirect_to subscribe_plan_path(id: @current_order)
    end
  end

  def save_data_to_subscribe_plan
    @current_order = @order_plan
    @current_user.skip_validate_password = true
    @current_user.update(user_params)
    if @current_user.valid?
      flash[:success] = Order.human_attribute_name(:data_saved)
      redirect_to subscribe_plan_path(id: @current_order.id)
    else
      flash[:error] = @current_user.errors.full_messages.join('<br>')
      render 'subscribe_plan'
    end
  end

  def save_address_to_subscribe_plan
    @current_order = @order_plan
    Order.validate_address_payment(@current_order, order_params[:address_attributes], order_params[:address_id])
    if @current_order.valid?
      @current_order.order_carts.each do |order_cart|
        order_cart.save
      end
      @current_order.save!
      flash[:success] = Order.human_attribute_name(:address_saved_sucess)
      redirect_to subscribe_plan_path(id: @current_order.id, show_pay_data: true)
    else
      flash[:error] = @current_order.errors.full_messages.join('<br>')
      redirect_to subscribe_plan_path(id: @current_order.id, show_address_data: true)
    end
  end

  def subscription
  end

  def subscription_payment
    authorize @subscription
    @current_order = Order.where(id: params[:order_id]).first
  end

  def cancel_subscription
    authorize @subscription
    Subscription.cancel_current_subscription(@subscription)
    redirect_back(fallback_location: :back)
  end

  def delete_subscription
    authorize @subscription
    if @subscription.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @order.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def generate_new_payment_subscription
    @current_order = Order.where(id: params[:order_id]).first
    service = Utils::PaymentService.new(PaymentTransaction::GATEWAY_PAGSEGURO, @current_order, @current_user, @system_configuration, nil, nil, nil, false)
    transaction = service.call

    if transaction[0]
      if transaction[1]
        flash[:success] = transaction[2]
        redirect_to subscription_payment_path(id: @subscription.id, order_id: @current_order.id)
      else
        flash[:error] = transaction[2]
        redirect_to subscribe_plan_path(id: @current_order.id)
      end
    else
      flash[:error] = transaction[2]
      redirect_to subscribe_plan_path(id: @current_order.id)
    end
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:id, :price, :order_status_id, :user_id, :installments, :payment_type_id, :total_freight_value, :card_id, :address_id,
      order_carts_attributes: [:id, :order_id, :ownertable_type, :ownertable_id, :quantity, :unity_price, :total_value, :freight_value, :freight_value_total],
      card_attributes: [:id, :card_banner_id, :name, :number, :validate_date_month, :validate_date_year, :ccv_code],
      address_attributes: [:id, :latitude, :longitude, :ownertable_type, :ownertable_id, :page_title, :address_type_id, :address_area_id, :name, :zipcode, :address, :district, :number, :complement, :address_type, :state_id, :city_id, :country_id, :reference, :validate_to_order]
      )
  end

  def user_params
    params
    .require(:user)
    .permit(:id, :name, :email, :access_user, :password, :password_confirmation, :recovery_token, 
      :profile_id, :is_blocked, :phone, :cpf, :rg, :birthday, 
      :social_name, :fantasy_name, :cnpj, :person_type_id, :sex_id, :profile_image, :current_password,
      :cellphone, :profession, :civil_state_id, :accept_therm,
      phones_attributes: [:id, :is_whatsapp, :phone_code, :phone, :phone_type_id, :responsible],
      emails_attributes: [:id, :email, :email_type_id],
      attachment_attributes: [:id, :attachment, :attachment_type],
      attachments_attributes: [:id, :attachment, :attachment_type],
      data_banks_attributes: [:id, :bank_id, :data_bank_type_id, :bank_number, :agency, :account, :operation, :assignor, :cpf_cnpj, :pix],
      data_bank_attributes: [:id, :bank_id, :data_bank_type_id, :bank_number, :agency, :account, :operation, :assignor, :cpf_cnpj, :pix],
      cards_attributes: [:id, :principal, :card_banner_id, :nickname, :name, :number, :ccv_code, :validate_date_month, :validate_date_year, :ownertable_type, :ownertable_id],
      address_attributes: [:id, :latitude, :longitude, :ownertable_type, :ownertable_id, :page_title, :address_type_id, :address_area_id, :name, :zipcode, :address, :district, :number, :complement, :address_type, :state_id, :city_id, :country_id, :reference],
      addresses_attributes: [:id, :latitude, :longitude, :ownertable_type, :ownertable_id, :page_title, :address_type_id, :address_area_id, :name, :zipcode, :address, :district, :number, :complement, :address_type, :state_id, :city_id, :country_id, :reference]
      )
  end

end
