class UsersController < ApplicationController
  skip_before_action :authenticate_user, :only => [:recovery_pass, :create_recovery_pass, :edit_pass, :update_pass]

  before_action :set_user, only: [
    :edit, :update, :destroy, :block,
    :save_data_to_buy, :change_data, :update_access_data,
    :destroy_profile_image, :user_addresses, :new_user_address, :user_cards,
    :reset_user_password
  ]

  before_action :set_address, only: [:edit_user_address, :update_user_address, :destroy_user_address]

  def users_admin
    authorize User

    if params[:admins_grid].nil? || params[:admins_grid].blank?
      @users = AdminsGrid.new(:current_user => @current_user)
      @users_to_export = AdminsGrid.new(:current_user => @current_user)
    else
      @users = AdminsGrid.new(params[:admins_grid].merge(current_user: @current_user))
      @users_to_export = AdminsGrid.new(params[:admins_grid].merge(current_user: @current_user))
    end

    if @current_user.admin?
      @users.scope {|scope| scope.page(params[:page]) }
    elsif @current_user.user?
      @users.scope {|scope| scope.page(params[:page]) }
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @users_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: User.human_attribute_name(:admin_users)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def users_user
    authorize User
    if params[:users_grid].nil? || params[:users_grid].blank?
      @users = UsersGrid.new(:current_user => @current_user)
      @users_to_export = UsersGrid.new(:current_user => @current_user)
    else
      @users = UsersGrid.new(params[:users_grid].merge(current_user: @current_user))
      @users_to_export = UsersGrid.new(params[:users_grid].merge(current_user: @current_user))
    end

    @users.scope {|scope| scope.page(params[:page]) }

    respond_to do |format|
      format.html
      format.csv do
        send_data @users_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: User.human_attribute_name(:common_users)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def users_client
    authorize User

    if params[:clients_grid].nil? || params[:clients_grid].blank?
      @users = ClientsGrid.new(:current_user => @current_user)
      @users_to_export = ClientsGrid.new(:current_user => @current_user)
    else
      @users = ClientsGrid.new(params[:clients_grid].merge(current_user: @current_user))
      @users_to_export = ClientsGrid.new(params[:clients_grid].merge(current_user: @current_user))
    end

    @users.scope {|scope| scope.page(params[:page]) }

    respond_to do |format|
      format.html
      format.csv do
        send_data @users_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: User.human_attribute_name(:client_users)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def users_manager
    authorize User

    if params[:managers_grid].nil? || params[:managers_grid].blank?
      @users = ManagersGrid.new(:current_user => @current_user)
      @users_to_export = ManagersGrid.new(:current_user => @current_user)
    else
      @users = ManagersGrid.new(params[:managers_grid].merge(current_user: @current_user))
      @users_to_export = ManagersGrid.new(params[:managers_grid].merge(current_user: @current_user))
    end

    if @current_user.admin?
      @users.scope {|scope| scope.page(params[:page]) }
    elsif @current_user.client?
      @users.scope {|scope| scope.by_client_id(@current_user.id).page(params[:page]) }
      @users_to_export.scope {|scope| scope.by_client_id(@current_user.id) }
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @users_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: User.human_attribute_name(:manager_users)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def users_additional
    authorize User

    if params[:additionals_grid].nil? || params[:additionals_grid].blank?
      @users = AdditionalsGrid.new(:current_user => @current_user)
      @users_to_export = AdditionalsGrid.new(:current_user => @current_user)
    else
      @users = AdditionalsGrid.new(params[:additionals_grid].merge(current_user: @current_user))
      @users_to_export = AdditionalsGrid.new(params[:additionals_grid].merge(current_user: @current_user))
    end

    if @current_user.admin?
      @users.scope {|scope| scope.page(params[:page]) }
    elsif @current_user.client?
      @users.scope {|scope| scope.by_client_id(@current_user.id).page(params[:page]) }
      @users_to_export.scope {|scope| scope.by_client_id(@current_user.id) }
    elsif @current_user.manager?
      @users.scope {|scope| scope.by_client_id(@current_user.client_id).page(params[:page]) }
      @users_to_export.scope {|scope| scope.by_client_id(@current_user.client_id) }
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @users_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: User.human_attribute_name(:additional_users)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def users_provider
    authorize User

    if params[:providers_grid].nil? || params[:providers_grid].blank?
      @users = ProvidersGrid.new(:current_user => @current_user)
      @users_to_export = ProvidersGrid.new(:current_user => @current_user)
    else
      @users = ProvidersGrid.new(params[:providers_grid].merge(current_user: @current_user))
      @users_to_export = ProvidersGrid.new(params[:providers_grid].merge(current_user: @current_user))
    end

    if @current_user.admin?
      @users.scope {|scope| scope.page(params[:page]) }
    elsif @current_user.additional? || @current_user.manager?
      state_ids = @current_user.client.states.map(&:id)
      @users.scope {|scope| scope.by_provider_state_ids(state_ids).page(params[:page]) }
      @users_to_export.scope {|scope| scope.by_provider_state_ids(state_ids) }
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @users_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: User.human_attribute_name(:provider_users)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def validate_users
    authorize User

    if params[:validate_users_grid].nil? || params[:validate_users_grid].blank?
      @users = ValidateUsersGrid.new(:current_user => @current_user)
      @users_to_export = ValidateUsersGrid.new(:current_user => @current_user)
    else
      @users = ValidateUsersGrid.new(params[:validate_users_grid].merge(current_user: @current_user))
      @users_to_export = ValidateUsersGrid.new(params[:validate_users_grid].merge(current_user: @current_user))
    end

    if @current_user.admin?
      @users.scope {|scope| scope.page(params[:page]) }
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @users_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: User.human_attribute_name(:validate_users)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def new
    authorize User
    if Rails.env.development?
      generate_data_user
    else
      @user = User.new
      @user.profile_id = params[:profile_id]
    end
    if @current_user.manager?
      @user.client_id = @current_user.client_id
    end
    if (@user.profile_id == Profile::PROVIDER_ID || @user.profile_id == Profile::ADMIN_ID) && !@current_user.admin?
      user_not_authorized
    end
    build_initials_relations
  end

  def generate_data_user
    @user = FactoryBot.build(:user, profile_id: params[:profile_id])
    @address = FactoryBot.build(:address, ownertable: @user)
    @user.address = @address
  end

  def block
    authorize @user

    if @user.is_blocked
      text = User.human_attribute_name(:reactived)
    else
      text = User.human_attribute_name(:inactive)
    end
    if @user.update_column(:is_blocked, !@user.is_blocked)
      if @user.is_blocked && @user.client?
        @user.vinculed_users.update_all(is_blocked: true)
      end
      flash[:success] = text+I18n.t('model.with_sucess')
    else
      flash[:error] = @user.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def create
    authorize User
    @user = User.new(user_params)

    if Rails.env.development?
      new_password = "123"
    else
      new_password = ('0'..'z').to_a.shuffle.first(8).join
    end
    @user.password = new_password
    @user.password_confirmation = new_password
    @user.skip_accept_therm = true
    @user.user_status_id = UserStatus::APROVADO_ID
    @user.validated_mail = true

    # if !@user.admin?
    #   @user.user_status_id = UserStatus::AGUARDANDO_AVALIACAO_ID
    #   if Rails.env.development?
    #   end
    # end

    if @user.save
      if !@user.client?
        # flash[:success] = t('flash.create')+"<br><br>"+t('model.password_sent')+"<br>"+t('model.password_generated')+new_password
        flash[:success] = t('flash.create')+"<br>"+t('model.password_sent')
        NotificationMailer.welcome(@user, @system_configuration, new_password).deliver_later
      else
        flash[:success] = User.human_attribute_name(:client_registered)
      end
      redirect
    else
      flash[:error] = @user.errors.full_messages.join('<br>')
      build_initials_relations
      render :new
    end
  end

  def edit
    authorize @user
    build_initials_relations
  end

  def update
    authorize @user
    @user.skip_validate_password = true
    if @current_user.admin?
      @user.skip_accept_therm = true
    end
    @user.update(user_params)
    if @user.valid?
      flash[:success] = t('flash.update')
      redirect_to change_data_path(id: @user.id)
    else
      flash[:error] = @user.errors.full_messages.join('<br>')
      build_initials_relations
      render :change_data
    end
  end

  def redirect
    if @user.admin?
      redirect_to users_admin_path
    elsif @user.client?
      redirect_to users_client_path
    elsif @user.manager?
      redirect_to users_manager_path
    elsif @user.additional?
      redirect_to users_additional_path
    elsif @user.provider?
      redirect_to users_provider_path
    end
  end

  def change_data
    authorize @user
    build_initials_relations
  end

  def update_access_data
    authorize @user
    valid = false
    if !user_params[:current_password].nil? || !user_params[:current_password].blank?
      if @user.authenticate(user_params[:current_password])
        if (user_params[:password].nil? || user_params[:password].blank?) && !user_params[:email].nil? && CustomHelper.address_valid?(user_params[:email])
          @user.update_columns(email: user_params[:email])
          valid = true
        else
          @user.update(user_params)
          if @user.valid?
            valid = true
          else
            message = @user.errors.full_messages.join('<br>')
          end
        end
      else
        message = User.human_attribute_name(:wrong_current_password)
        flash[:error] = User.human_attribute_name(:wrong_current_password)
      end
    else
      message = User.human_attribute_name(:wrong_current_password)
      flash[:error] = User.human_attribute_name(:wrong_current_password)
    end
    if valid
      flash[:success] = t('flash.update')
      redirect_to change_data_path(id: @user.id)
    else
      flash[:error] = message
      render :change_data
    end
  end

  def reset_user_password
    authorize @user
    begin
      if Rails.env.development?
        new_password = "123"
      else
        new_password = ('0'..'z').to_a.shuffle.first(8).join
      end
      @user.password = new_password
      @user.password_confirmation = new_password
      @user.save(validate: false)
      NotificationMailer.reset_password(@user, @system_configuration, new_password).deliver_later
      data = {
        result: true,
        password: new_password
      }
      # flash[:success] = User.human_attribute_name(:reset_user_password_success)
    rescue Exception => e
      data = {
        result: false,
        errors: e.message
      }
    end
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def build_initials_relations
    if @user.person_contacts.select{ |item| item[:id].nil? }.length == 0
      @user.person_contacts.build
    end
    @user.build_address(address_area_id: AddressArea::GENERAL_ID) if @user.address.nil?
    @user.build_data_bank if @user.data_bank.nil?
    # @user.build_attachment if @user.attachment.nil?
  end

  def destroy
    authorize @user
    if @user.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @user.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def destroy_profile_image
    authorize @user
    @user.profile_image.purge
    result = true
    data = {
      result: result
    }
    respond_to do |format|
      format.html
      format.json {render :json => data, :status => 200}
    end
  end

  def generate_contract
    authorize User
    doc_replace = DocxReplace::Doc.new("#{Rails.root}/app/contracts/contrato_exemplo.docx", "#{Rails.root}/tmp")

    # Formata os caracteres do documento para conseguir substituir
    FormatDocWordToReplace.word_xml_gsub!(doc_replace.instance_variable_get(:@document_content), '$nome_cliente$', @current_user.name)
    FormatDocWordToReplace.word_xml_gsub!(doc_replace.instance_variable_get(:@document_content), '$numero_contrato$', @current_user.id.to_s)

    tmp_file = Tempfile.new('word_tempate', "#{Rails.root}/tmp")
    doc_replace.commit(tmp_file.path)
    send_file tmp_file.path, filename: "user_#{@current_user.id}_contract.docx", disposition: 'attachment'
  end

  def recovery_pass
  end

  def create_recovery_pass
    user = User.active.find_by_email(recover_params)
    if user
      user.update_column(:recovery_token, SecureRandom.urlsafe_base64)
      NotificationMailer.forgot_password(user, @system_configuration).deliver_later
      flash[:success] = t('flash.change_password')
      redirect_to login_path
    else
      flash[:error] = t('flash.change_password_error')
      render 'recovery_pass'
    end
  end

  def edit_pass
    if params[:recovery_token]
      session[:user_id] = nil
      @user = User.find_by_recovery_token params[:recovery_token]
    end

    @user = current_user if current_user

    if !@user
      flash[:error] = t('flash.change_password_error')
      redirect_to login_path
    end
  end

  def update_pass
    @user = User.active.find(params[:id])
    if user_params[:password].nil? || user_params[:password].blank?
      flash[:error] = User.human_attribute_name(:invalid_password)
      redirect_back(fallback_location: :back)
    else
      if @user.update(user_params)
        session[:user_id] = @user.id
        @user.update_columns(recovery_token: nil)
        flash[:success] = t('flash.update')
        redirect_to change_data_path(id: @user.id)
      else
        flash[:error] = @user.errors.full_messages.join('<br>')
        redirect_back(fallback_location: :back)
      end
    end
  end

  def delete_address
    address = Address.where(id: params[:model_id]).first
    if address
      address.destroy
      flash[:success] = t('flash.destroy')
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def delete_order_service_invoice
    order_service_invoice = OrderServiceInvoice.where(id: params[:model_id]).first
    if order_service_invoice
      order_service_invoice.destroy
      flash[:success] = t('flash.destroy')
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def delete_order_service_proposal_item
    order_service_proposal_item = OrderServiceProposalItem.where(id: params[:model_id]).first
    if order_service_proposal_item
      order_service_proposal_item.destroy
      flash[:success] = t('flash.destroy')
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def delete_provider_service_temp
    provider_service_temp = ProviderServiceTemp.where(id: params[:model_id]).first
    if provider_service_temp
      provider_service_temp.destroy
      flash[:success] = t('flash.destroy')
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def delete_phone
    phone = Phone.where(id: params[:model_id]).first
    if phone
      phone.destroy
      flash[:success] = t('flash.destroy')
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def delete_email
    email = Email.where(id: params[:model_id]).first
    if email
      email.destroy
      flash[:success] = t('flash.destroy')
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def delete_sub_unit
    sub_unit = SubUnit.where(id: params[:model_id]).first
    if sub_unit
      sub_unit.vehicles.update_all(sub_unit_id: nil)
      sub_unit.destroy
      flash[:success] = t('flash.destroy')
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def delete_attachment
    attachment = Attachment.where(id: params[:model_id]).first
    if attachment
      attachment_storage = ActiveStorage::Attachment.where(id: attachment.attachment.id).first
      if Rails.env.development? && attachment_storage && !attachment_storage.key.nil?
        attachment_key_split = attachment_storage.key.split("/")
        new_key = ENV['AWS_BUCKET_PREFIX']+attachment_key_split[2]
        attachment_storage.blob.update_columns(key: new_key)
        attachment.reload
      end
      if attachment_storage
        attachment_storage.purge
      end
      attachment.destroy
      flash[:success] = t('flash.destroy')
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def delete_data_bank
    data_bank = DataBank.where(id: params[:model_id]).first
    if data_bank
      data_bank.destroy
      flash[:success] = t('flash.destroy')
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def delete_card
    card = Card.where(id: params[:model_id]).first
    if card
      card.destroy
      flash[:success] = t('flash.destroy')
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def delete_data_plan_periodicity
    data_plan_periodicity = DataPlanPeriodicity.where(id: params[:model_id]).first
    if data_plan_periodicity
      data_plan_periodicity.destroy
      flash[:success] = t('flash.destroy')
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def delete_person_contact
    person_contact = PersonContact.where(id: params[:model_id]).first
    if person_contact
      person_contact.destroy
      flash[:success] = t('flash.destroy')
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def delete_addendum_contract
    addendum_contract = AddendumContract.where(id: params[:model_id]).first
    if addendum_contract
      if addendum_contract.can_delete?
        addendum_contract.destroy
        flash[:success] = t('flash.destroy')
      else
        flash[:error] = addendum_contract.reason_cannot_delete
      end
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def delete_part_service_order_service
    part_service_order_service = PartServiceOrderService.where(id: params[:model_id]).first
    if part_service_order_service
      part_service_order_service.destroy
      flash[:success] = t('flash.destroy')
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def delete_cancel_commitment
    cancel_commitment = CancelCommitment.where(id: params[:model_id]).first
    if cancel_commitment
      canceled_value = cancel_commitment.commitment.canceled_value
      new_canceled_value = canceled_value - cancel_commitment.value
      cancel_commitment.commitment.update(canceled_value: new_canceled_value)
      cancel_commitment.destroy
      flash[:success] = t('flash.destroy')
      redirect_back(fallback_location: :back)
    else
      redirect_to change_data_path(id: @current_user.id)
    end
  end

  def save_data_to_buy
    define_current_order
    @user.skip_validate_password = true
    @user.update(user_params)
    if @user.valid?
      flash[:success] = Order.human_attribute_name(:data_saved)
      if !@current_order.is_address_valid? || !params[:show_address_data].nil?
        redirect_to pay_order_path(id: @current_order.id, show_address_data: true)
      else
        redirect_to pay_order_path(id: @current_order.id)
      end
    else
      flash[:error] = @user.errors.full_messages.join('<br>')
      render 'users/pay_order'
    end
  end

  def define_current_order
    if @current_user.nil?
      @order.save!
      @current_order = @order
    elsif !session[:current_order_id].nil?
      @current_order = Order.where(id: session[:current_order_id]).first
    else
      @order.user_id = @current_user.id
      @order.save!
      @current_order = @order
    end
  end

  def send_push_test
    authorize User
  end

  def send_push_to_mobile
    authorize User
    data = {
      foo: "bar"
    }
    if params[:service] == "Firebase"
      service = Utils::PushNotification::DispareNotificationService.new(params[:title], params[:message], [params[:mobile_code]], data)
      Rails.logger.info service.call
    else
      name = params[:message]
      include_player_ids = [
        params[:mobile_code]
      ]
      headings = {
        pt: params[:title],
        en: params[:title]
      }
      contents = {
        pt: params[:message],
        en: params[:message]
      }
      service = Utils::OneSignal::CreateNotificationService.new(name, include_player_ids, data, headings, contents)
      Rails.logger.info service.call
    end
    redirect_back(fallback_location: :back)
  end

  def user_addresses
    if @user.nil? && !params[:addresses_grid][:ownertable_id].nil?
      @user = User.where(id: params[:addresses_grid][:ownertable_id]).first
    end
    authorize @user

    if params[:addresses_grid].nil? || params[:addresses_grid].blank?
      @addresses = AddressesGrid.new(current_user: @current_user,
        ownertable_type: params[:ownertable_type],
        ownertable_id: params[:id],
        address_area_id: params[:address_area_id],
        page_title: params[:page_title])
    else
      @addresses = AddressesGrid.new(params[:addresses_grid].merge(current_user: @current_user,
        ownertable_type: params[:ownertable_type],
        ownertable_id: params[:id],
        address_area_id: params[:address_area_id],
        page_title: params[:page_title]))
    end

    define_variables

    if @current_user.admin?
      @addresses.scope {
        |scope| scope
        .by_ownertable_type("User")
        .by_ownertable_id(params[:id])
        .by_address_area_id(params[:address_area_id])
        .page(params[:page])
      }
    elsif @current_user.user?
      @addresses.scope {
        |scope| scope
        .by_ownertable_type("User")
        .by_ownertable_id(@current_user.id)
        .by_address_area_id(params[:address_area_id])
        .page(params[:page])
      }
    end

    respond_to do |format|
      format.html
    end
  end

  def define_variables
    @ownertable_type = ""
    @ownertable_id = ""
    @address_area_id = ""
    @page_title = ""

    if !params[:ownertable_type].nil?
      @ownertable_type = params[:ownertable_type]
      @ownertable_id = params[:id]
      @address_area_id = params[:address_area_id]
      @page_title = params[:page_title]
    elsif !params[:addresses_grid][:ownertable_type].nil?
      @ownertable_type = params[:addresses_grid][:ownertable_type]
      @ownertable_id = params[:addresses_grid][:ownertable_id]
      @address_area_id = params[:addresses_grid][:address_area_id]
      @page_title = params[:addresses_grid][:page_title]
    end
  end

  def new_user_address
    authorize @user
    @address = Address.new(ownertable_type: params[:ownertable_type], ownertable_id: params[:id], address_area_id: params[:address_area_id], page_title: params[:page_title])
    @page_title = params[:page_title]
  end

  def edit_user_address
    if policy(@address.ownertable).edit_user_address?(@address)
      @address.page_title = params[:page_title]
      @page_title = params[:page_title]
    else
      user_not_authorized
    end
  end

  def create_user_address
    @user = User.where(id: address_params[:ownertable_id]).first
    authorize @user
    @address = Address.new(address_params)
    if @address.save
      flash[:success] = t('flash.create')
      redirect_to user_addresses_path(ownertable_type: @address.ownertable_type, id: @address.ownertable_id, address_area_id: @address.address_area_id, page_title: @address.page_title)
    else
      flash[:error] = @address.errors.full_messages.join('<br>')
      @page_title = @address.page_title
      render :new_user_address
    end
  end

  def update_user_address
    if policy(@address.ownertable).update_user_address?(@address)
      @address.update(address_params)
      if @address.valid?
        flash[:success] = t('flash.update')
        redirect_to user_addresses_path(ownertable_type: @address.ownertable_type, id: @address.ownertable_id, address_area_id: @address.address_area_id, page_title: @address.page_title)
      else
        flash[:error] = @address.errors.full_messages.join('<br>')
        @page_title = @address.page_title
        render :edit_user_address
      end
    else
      user_not_authorized
    end
  end

  def destroy_user_address
    if policy(@address.ownertable).destroy_user_address?(@address)
      if @address.destroy
        flash[:success] = t('flash.destroy')
      else
        flash[:error] = @address.errors.full_messages.join('<br>')
      end
      redirect_back(fallback_location: :back)
    else
      user_not_authorized
    end
  end

  def user_cards
    authorize @user

    if params[:cards_grid].nil? || params[:cards_grid].blank?
      @cards = CardsGrid.new(current_user: @current_user,
        ownertable_type: params[:ownertable_type],
        ownertable_id: params[:id],
        page_title: params[:page_title])
    else
      @cards = CardsGrid.new(params[:cards_grid].merge(current_user: @current_user,
        ownertable_type: params[:ownertable_type],
        ownertable_id: params[:id],
        page_title: params[:page_title]))
    end

    define_variables_cards

    @card = Card.new(ownertable_type: params[:ownertable_type], ownertable_id: params[:id], page_title: params[:page_title])

    if @current_user.admin?
      @cards.scope {
        |scope| scope
        .by_ownertable_type("User")
        .by_ownertable_id(params[:id])
        .page(params[:page])
      }
    elsif @current_user.user?
      @cards.scope {
        |scope| scope
        .by_ownertable_type("User")
        .by_ownertable_id(@current_user.id)
        .page(params[:page])
      }
    end

    respond_to do |format|
      format.html
    end
  end

  def define_variables_cards
    @ownertable_type = ""
    @ownertable_id = ""
    @page_title = ""

    if !params[:ownertable_type].nil?
      @ownertable_type = params[:ownertable_type]
      @ownertable_id = params[:id]
      @page_title = params[:page_title]
    elsif !@card.ownertable_type.nil?
      @ownertable_type = @card.ownertable_type
      @ownertable_id = @card.ownertable_id
      @page_title = @card.page_title
    end
  end

  def create_user_card
    @user = User.where(id: card_params[:ownertable_id]).first
    authorize @user
    @card = Card.new(card_params)
    if @card.save
      flash[:success] = t('flash.create')
      redirect_to user_cards_path(ownertable_type: @card.ownertable_type, id: @card.ownertable_id, page_title: Card.model_name.human(count: 2))
    else
      flash[:error] = @card.errors.full_messages.join('<br>')
      redirect_to user_cards_path(ownertable_type: @card.ownertable_type, id: @card.ownertable_id, page_title: @card.page_title)
    end
  end

  def destroy_user_card
    authorize @card.ownertable
    if @card.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @card.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def destroy_attachment
    authorize @current_user
    attachment = ActiveStorage::Attachment.where(id: params[:attachment_id]).first
    if attachment
      attachment.purge
      flash[:success] = t('flash.destroy')
    end
    redirect_back(fallback_location: :back)
  end

  def approve_users
    authorize User
    result = true
    begin
      users_ids = params[:users_ids].split(",")
      all_users = User.where(id: [users_ids])
      all_users.each do |user|
        user.update_columns(user_status_id: UserStatus::APROVADO_ID)
        NotificationMailer.approve_user(user, @system_configuration).deliver_later
      end
      message = User.human_attribute_name(:approved_users)
    rescue Exception => e
      result = false
      message = e.message
    end
    data = {
      result: result,
      message: message
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def disapprove_users
    authorize User
    result = true
    begin
      users_ids = params[:users_ids].split(",")
      all_users = User.where(id: [users_ids])
      all_users.each do |user|
        user.update_columns(user_status_id: UserStatus::REPROVADO_ID)
        NotificationMailer.disapprove_user(user, params[:disapprove_reason], @system_configuration).deliver_later
      end
      message = User.human_attribute_name(:disapproved_users)
    rescue Exception => e
      result = false
      message = e.message
    end
    data = {
      result: result,
      message: message
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def getting_cost_centers_and_vehicles
    cost_centers = CostCenter.where(client_id: params[:client_id])
    cost_centers_ids = cost_centers.map(&:id)
    vehicles = Vehicle.where(cost_center_id: [cost_centers_ids])
    data = {
      cost_centers: cost_centers,
      vehicles: vehicles
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def managers_by_client_id
    data = {
      result: User.manager.by_client_id([params[:client_id]])
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  private

  def set_user
    @user = User.find_by_id(params[:id])
  end

  def set_address
    @address = Address.find_by_id(params[:id])
  end

  def recover_params
    params.require(:recovery_pass).permit(:email)[:email]
  end

  def user_params
    params
    .require(:user)
    .permit(:id, :name, :email, :access_user, :password, :password_confirmation, :recovery_token,
      :profile_id, :is_blocked, :phone, :cpf, :rg, :birthday,
      :social_name, :fantasy_name, :cnpj, :person_type_id, :sex_id, :profile_image, :current_password,
      :cellphone, :profession, :civil_state_id, :accept_therm, :property_regime_id, :user_status_id,
      :current_plan_id, :set_manually_plan, :manually_plan_id, :limit_date_manually_plan,
      :municipal_inscription, :state_inscription, :discount_percent, :department, :state_id, :city_id, :client_id,
      :registration, :optante_simples, :needs_km,
        :require_vehicle_photos,
      phones_attributes: [:id, :is_whatsapp, :phone_code, :phone, :phone_type_id, :responsible],
      emails_attributes: [:id, :email, :email_type_id],
      attachment_attributes: [:id, :attachment, :attachment_type],
      attachments_attributes: [:id, :attachment, :attachment_type],
      data_banks_attributes: [:id, :bank_id, :data_bank_type_id, :bank_number, :agency, :account, :operation, :assignor, :cpf_cnpj, :pix],
      data_bank_attributes: [:id, :bank_id, :data_bank_type_id, :agency, :account, :operation, :cpf_cnpj, :pix],
      cards_attributes: [:id, :principal, :card_banner_id, :nickname, :name, :number, :ccv_code, :validate_date_month, :validate_date_year, :ownertable_type, :ownertable_id],
      address_attributes: [:id, :latitude, :longitude, :ownertable_type, :ownertable_id, :page_title, :address_type_id, :address_area_id, :name, :zipcode, :address, :district, :number, :complement, :address_type, :state_id, :city_id, :country_id, :reference],
      addresses_attributes: [:id, :latitude, :longitude, :ownertable_type, :ownertable_id, :page_title, :address_type_id, :address_area_id, :name, :zipcode, :address, :district, :number, :complement, :address_type, :state_id, :city_id, :country_id, :reference],
      person_contacts_attributes: [:id, :ownertable_type, :ownertable_id, :name, :phone, :email, :office],
      provider_service_type_ids: [], associated_cost_center_ids: [], associated_sub_unit_ids: [], state_ids: []
      )
  end

  def address_params
    params
    .require(:address)
    .permit(:id, :ownertable_type, :ownertable_id,
      :address_type_id, :address_area_id,
      :name, :zipcode, :address, :district, :number,
      :complement, :address_type, :state_id,
      :page_title,
      :city_id, :country_id, :reference)
  end

  def card_params
    params
    .require(:card)
    .permit(:id, :ownertable_type, :ownertable_id,
      :principal, :card_banner_id, :nickname, :name, :page_title,
      :number, :ccv_code, :validate_date_month, :validate_date_year)
  end

end
