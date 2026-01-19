module Api  
  module V1
    class DataBanks < Grape::API
      include Api::V1::Defaults

      resource :data_banks do

        #POST /data_banks
        post "" do
          authenticate!
          @data_bank = DataBank.new(params)
          @data_bank.ownertable = @current_user
          if @data_bank.save
            {status: 'success', data_bank: @data_bank}
          else
            {status: 'failed', errors: @data_bank.errors, errors_message: @data_bank.errors.full_messages.join('<br>')}
          end
        end

        #GET /data_banks
        paginate
        get "" do
          authenticate!
          @current_user.data_banks.page(params[:page])
        end

        #GET /data_banks/:id
        params do
          requires :id
        end
        get "/:id" do
          authenticate!
          @data_bank = @current_user.data_banks.where(id: params[:id]).first
          if !@data_bank.nil?
            @data_bank
          else
            []
          end
        end

        #PUT /data_banks/:id
        params do
          requires :id
        end
        put "/:id" do
          authenticate!
          @data_bank = @current_user.data_banks.where(id: params[:id]).first
          if !@data_bank.nil?
            @data_bank.update(params)
            if @data_bank.valid?
              {status: 'success', data_bank: @data_bank}
            else
              {status: 'failed', errors: @data_bank.errors, errors_message: @data_bank.errors.full_messages.join('<br>')}
            end
          else
            {status: 'failed', errors: DataBank.model_name.human+" "+I18n.t("model.not_found").downcase}
          end
        end

        #DELETE /data_banks/:id
        params do
          requires :id
        end
        delete "/:id" do
          authenticate!
          @data_bank = @current_user.data_banks.where(id: params[:id]).first
          if !@data_bank.nil?
            if @data_bank.destroy
              {status: 'success'}
            else
              {status: 'failed'}
            end
          else
            {status: 'failed', errors: DataBank.model_name.human+" "+I18n.t("model.not_found").downcase}
          end
        end

      end

    end
  end
end