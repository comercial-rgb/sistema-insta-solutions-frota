class SessionsController < ApplicationController

	skip_before_action :authenticate_user

	# Descomentar caso queira timeout de conexão
	# def active
	# 	render_session_status
	# end

	# def timeout
	# 	gflash :error => "Deslogado por inatividade.."
	# 	render_session_timeout
	# end

	def new
		redirect
	end

	def update_locale
		service = Utils::Locale::ChangeLocaleService.new(params[:locale], session)
		result = service.call
		I18n.default_locale = result[1].to_sym
		session[:locale] = result[1]
		redirect_back(fallback_location: :back)
	end

	def create
		if !params[:email].nil? && !params[:email].blank?
			create_by_mail
		elsif !request.env["omniauth.auth"].nil?
			auth = request.env["omniauth.auth"]
			create_by_omniauth(auth)
		else
			redirect_to login_path
		end
	end

	def create_by_mail
		begin
			user = User.active.find_by_email params[:email].strip.downcase
			if user && user.authenticate(params[:password])
				if !user.client?
					session[:user_id] = user.id
					flash[:success] = t('flash.login')
					if !session[:current_pay_order].nil? && !session[:current_pay_order].blank?
						redirect_pay_order
					elsif !session[:current_plan_subscribe].nil? && !session[:current_plan_subscribe].blank?
						redirect_to subscribe_plan_path
					else
						redirect
					end
				else
					flash[:error] = t('flash.login_mail_validation')
					@user = User.new
					render "new"
				end
			else
				flash[:error] = t('flash.login_error')
				@user = User.new
				render "new"
			end
		rescue Exception => e
			Rails.logger.error e.message
			redirect_to login_path
		end
	end

	def create_by_omniauth(auth)
		begin
			result = User.find_or_create_from_auth_hash(auth)
			if result[0]
		  		session[:user_id] = result[1].id
		  		flash[:success] = t('flash.login')
		  		redirect
		  	else
		  		session[:user_id] = nil
		  		flash[:error] = result[2]
		  		redirect_to login_path
			end
		rescue Exception => e
			Rails.logger.error e.message
			redirect_to login_path
		end
	end

	def redirect
		if !session[:user_id].nil?
			logged_user = User.where(:id => session[:user_id]).first
			if !logged_user.nil?
				if !session[:redirect_path].nil? && !session[:redirect_path].blank?
					# Redirecionando para o link acessado anteriormente
					current_redirect = session[:redirect_path]
					session[:redirect_path] = nil
					redirect_to current_redirect
				elsif !session[:current_pay_order].nil? && !session[:current_pay_order].blank?
					redirect_pay_order
				elsif !session[:current_plan_subscribe].nil? && !session[:current_plan_subscribe].blank?
					redirect_to subscribe_plan_path
				else
				if logged_user.provider?
					redirect_to provider_dashboard_path
				elsif logged_user.admin? || logged_user.manager? || logged_user.additional?
						redirect_to dashboard_path
					else
						redirect_to show_order_services_path(order_service_status_id: OrderServiceStatus::EM_ABERTO_ID)
					end
				end
			else
				destroy
			end
		end
	end

	def redirect_pay_order
		current_pay_order = session[:current_pay_order]
		session[:current_pay_order] = nil
		redirect_to pay_order_path(id: current_pay_order)
	end

	def destroy
		session[:user_id] = nil
		flash[:success] = t('flash.logout')
		redirect_to root_path
	end

	def visitors_new_user
		if @current_user.nil?
			if Rails.env.development?
				@user = FactoryBot.build(:user, profile_id: Profile::USER_ID, password: "hX2C@cAnF2", seed: true)
			else
				@user = User.new(person_type_id: PersonType::FISICA_ID, profile_id: Profile::USER_ID)
			end
		else
			redirect_to root_path
		end
	end

	def create_user
		@user = User.new(user_params)
		@user.new_user = true
		@user.current_plan_id = Plan::GRATUITO_ID
		@show_error_recaptcha = false
		@user.validate_mail_token = SecureRandom.urlsafe_base64
		if verify_recaptcha(model: @user)
			if @user.save
				NotificationMailer.welcome(@user, @system_configuration, nil).deliver_later
				flash[:success] = t('flash.create')+"<br>"+t('flash.login_mail_validation')
				redirect_to login_path
			else
				flash[:error] = @user.errors.full_messages.join('<br>')
				render :visitors_new_user
			end
		else
			@show_error_recaptcha = true
			render :visitors_new_user
		end
	end

	def validate_mail
		@user = User.where(validate_mail_token: params[:validate_mail_token]).first
		if !@user.nil?
			authorize @user
			@user.update_columns(validated_mail: true, validate_mail_token: nil)
		else
			flash[:error] = User.human_attribute_name(:user_already_validated)
			redirect_to login_path
		end
	end

	private

	def user_params
		params
		.require(:user)
		.permit(:id,
			:external_register,
			:name,
			:email,
			:password,
			:new_user,
			:accept_therm,
			:password_confirmation,
			:profile_id,
			:person_type_id)
	end
end
