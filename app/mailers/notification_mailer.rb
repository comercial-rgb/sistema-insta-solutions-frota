class NotificationMailer < ApplicationMailer

	default from: I18n.t('session.project')+' <comercial@instasolutions.com.br>'
	TO_DEVELOPMENT = "andre.sulivam@sulivam.com.br"

	def forgot_password(user, system_configuration)
		user.reload if user.persisted?
		@user = user
		address = @user.email
		if Rails.env.development?
			address = TO_DEVELOPMENT
		end
		if CustomHelper.address_valid?(address)
			mail(to: address, subject: t("subject_mails.forgot_password"))
		end
	end

	def reset_password(user, system_configuration, new_password)
		@user = user
		@new_password = new_password
		address = @user.email
		if Rails.env.development?
			address = TO_DEVELOPMENT
		end
		if CustomHelper.address_valid?(address) && Rails.env.production?
			mail(to: address, subject: t("subject_mails.reset_password"))
		end
	end

	def welcome(user, system_configuration, password)
		@user = user
		@password = password
		address = @user.email
		if Rails.env.development?
			address = TO_DEVELOPMENT
		end
		if CustomHelper.address_valid?(address) && Rails.env.production?
			mail(to: address, subject: t("subject_mails.welcome"))
		end
	end

	def new_site_contact_user(site_contact, user, system_configuration)
		@site_contact = site_contact
		@user = user
		@system_configuration = system_configuration
		to = @system_configuration.notification_mail
		address = @site_contact.email
		if Rails.env.development?
			address = TO_DEVELOPMENT
			to = TO_DEVELOPMENT
		end
		if CustomHelper.address_valid?(to) && Rails.env.production?
			mail(reply_to: address, to: to, subject: t("subject_mails.new_site_contact_user")+' - '+site_contact.name)
		end
	end

	def new_site_contact_confirm_message(site_contact, user, system_configuration)
		@site_contact = site_contact
		@user = user
		@system_configuration = system_configuration
		reply_to = @system_configuration.notification_mail
		address = @site_contact.email
		if Rails.env.development?
			address = TO_DEVELOPMENT
		end
		if CustomHelper.address_valid?(address) && Rails.env.production?
			mail(to: address, reply_to: reply_to, subject: t("subject_mails.new_site_contact_confirm_message")+' - '+site_contact.name)
		end
	end

	def plan_subscription(subscription, order)
		@subscription = subscription
		@order = order
		@user = subscription.user
		address = @user.email
		if Rails.env.development?
			address = TO_DEVELOPMENT
		end
		if CustomHelper.address_valid?(address) && Rails.env.production?
			mail(to: address, subject: t("subject_mails.plan_subscription"))
		end
	end

	def approve_user(user, system_configuration)
		@user = user
		address = @user.email
		if Rails.env.development?
			address = TO_DEVELOPMENT
		end
		if CustomHelper.address_valid?(address)
			mail(to: address, subject: t("subject_mails.approve_user"))
		end
	end

	def disapprove_user(user, disapprove_reason, system_configuration)
		@user = user
		@disapprove_reason = disapprove_reason
		address = @user.email
		if Rails.env.development?
			address = TO_DEVELOPMENT
		end
		if CustomHelper.address_valid?(address)
			mail(to: address, subject: t("subject_mails.disapprove_user"))
		end
	end

	def webhook_failure_alert(order_service, error_message)
		@order_service = order_service
		@error_message = error_message
		@os_code = order_service&.code || 'N/A'
		@client_name = order_service&.client&.fantasy_name || order_service&.client&.social_name || 'N/A'

		# Envia para todos os admins aprovados (excluindo emails fictícios que causam bounce)
		admin_emails = User.admin.where(user_status_id: UserStatus::APROVADO_ID).pluck(:email).compact.select { |e| CustomHelper.address_valid?(e) && CustomHelper.email_not_blocked?(e) }

		if admin_emails.any?
			mail(
				to: admin_emails,
				subject: "[ALERTA] Falha no envio da OS #{@os_code} ao Portal Financeiro"
			)
		end
	end

end
