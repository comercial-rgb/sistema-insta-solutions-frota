module Api  
  module V1
    class SiteContacts < Grape::API
      include Api::V1::Defaults

      resource :site_contacts do

        #POST /site_contacts
        post "" do
          current_user
          @site_contact = SiteContact.new(params)
          if @current_user
            @site_contact.user_id = @current_user.id
            @site_contact.name = @current_user.name
            @site_contact.phone = @current_user.phone
            @site_contact.email = @current_user.email
          end
          if @site_contact.save
            @system_configuration = SystemConfiguration.first
            NotificationMailer.new_site_contact_user(@site_contact, @current_user, @system_configuration).deliver_later
            NotificationMailer.new_site_contact_confirm_message(@site_contact, @current_user, @system_configuration).deliver_later
            {status: 'success', site_contact: @site_contact}
          else
            {status: 'failed', errors: @site_contact.errors, errors_message: @site_contact.errors.full_messages.join('<br>')}
          end
        end

      end

    end
  end
end
