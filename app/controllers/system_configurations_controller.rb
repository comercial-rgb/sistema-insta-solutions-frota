class SystemConfigurationsController < ApplicationController

    def edit
        authorize SystemConfiguration
        build_initials_relations
    end

    def update
        authorize SystemConfiguration
        @system_configuration.update(system_configuration_params)
        if @system_configuration.valid?
            SystemConfiguration.getting_latitude_longitude_address(@system_configuration)
            flash[:success] = t('flash.update')
            redirect_to edit_system_configuration_path(1)
        else
            flash[:error] =  @system_configuration.errors.full_messages.join('<br>')
            build_initials_relations
            render :edit
        end
    end

    def build_initials_relations
        @system_configuration.build_address(address_area_id: AddressArea::GENERAL_ID) if @system_configuration.address.nil?
    end

    def delete_gerencia_net_certificate
        authorize SystemConfiguration
        @system_configuration.gerencia_net_certificate.purge
        flash[:success] = t('flash.destroy')
        redirect_to edit_system_configuration_path(1)
    end

    private

    def system_configuration_params
        params
        .require(:system_configuration)
        .permit(:notification_mail, :contact_mail, :privacy_policy, :use_policy, :warranty_policy, :exchange_policy, :phone, :cellphone, :data_security_policy, :quality, :about, :about_image, :about_video_link,
            :mission, :view, :values, :site_link, :facebook_link, :instagram_link, :twitter_link, :youtube_link, :client_logo, :cnpj, :id_google_analytics, :page_title, :page_description, :favicon, :geral_conditions,
            :contract_data, :attendance_data, :pix_limit_payment_minutes, :gerencia_net_certificate, :notification_new_users, :notification_validation_users,
            :about_product, :provider_contract,
            address_attributes: [:id, :latitude, :longitude, :ownertable_type, :ownertable_id, :page_title, :address_type_id, :address_area_id, :name, :zipcode, :address, :district, :number, :complement, :address_type, :state_id, :city_id, :country_id, :reference])
    end

end
