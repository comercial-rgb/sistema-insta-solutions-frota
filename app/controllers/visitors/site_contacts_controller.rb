class Visitors::SiteContactsController < ApplicationController
	skip_before_action :authenticate_user

	def new
		@site_contact = SiteContact.new
	end

	def create
		@site_contact = SiteContact.new(site_contact_params)
		@site_contact.name = @current_user.name
		@site_contact.user_id = @current_user.id
		if @site_contact.save
			flash[:success] = SiteContact.human_attribute_name(:success_save)
			NotificationMailer.new_site_contact_user(@site_contact, @current_user, @system_configuration).deliver_later
			NotificationMailer.new_site_contact_confirm_message(@site_contact, @current_user, @system_configuration).deliver_later
			redirect_to visitors_new_site_contact_path
		else
			flash[:error] = @site_contact.errors.full_messages.join('<br>')
			render :new
		end
	end

	private

	def site_contact_params
		params
		.require(:site_contact)
		.permit(:name,
			:email,
			:phone,
			:site_contact_subject_id,
			:user_id,
			:message)
	end

end
