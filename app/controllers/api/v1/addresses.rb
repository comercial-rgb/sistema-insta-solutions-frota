module Api  
  module V1
    class Addresses < Grape::API
      include Api::V1::Defaults

      resource :addresses do

        #POST /addresses
        post "" do
          authenticate!
          @address = Address.new(params)
          @address.ownertable = @current_user
          if @address.save
            {status: 'success', address: @address}
          else
            {status: 'failed', errors: @address.errors, errors_message: @address.errors.full_messages.join('<br>')}
          end
        end

        #GET /addresses
        paginate
        get "" do
          authenticate!
          @current_user.addresses.page(params[:page])
        end

        #GET /addresses/:id
        params do
          requires :id
        end
        get "/:id" do
          authenticate!
          @address = @current_user.addresses.where(id: params[:id]).first
          if !@address.nil?
            @address
          else
            []
          end
        end

        #PUT /addresses/:id
        params do
          requires :id
        end
        put "/:id" do
          authenticate!
          @address = @current_user.addresses.where(id: params[:id]).first
          if !@address.nil?
            @address.update(params)
            if @address.valid?
              {status: 'success', address: @address}
            else
              {status: 'failed', errors: @address.errors, errors_message: @address.errors.full_messages.join('<br>')}
            end
          else
            {status: 'failed', errors: Address.model_name.human+" "+I18n.t("model.not_found").downcase}
          end
        end

        #DELETE /addresses/:id
        params do
          requires :id
        end
        delete "/:id" do
          authenticate!
          @address = @current_user.addresses.where(id: params[:id]).first
          if !@address.nil?
            if @address.destroy
              {status: 'success'}
            else
              {status: 'failed'}
            end
          else
            {status: 'failed', errors: Address.model_name.human+" "+I18n.t("model.not_found").downcase}
          end
        end

      end

    end
  end
end