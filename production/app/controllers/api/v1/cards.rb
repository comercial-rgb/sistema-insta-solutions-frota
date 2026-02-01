module Api  
  module V1
    class Cards < Grape::API
      include Api::V1::Defaults

      resource :cards do

        #POST /cards
        post "" do
          authenticate!
          @card = Card.new(params)
          @card.ownertable = @current_user
          if @card.save
            {status: 'success', formatted_name: @card.get_formatted_name, formatted_validate_date: @card.get_formatted_validate_date}
          else
            {status: 'failed', errors: @card.errors, errors_message: @card.errors.full_messages.join('<br>')}
          end
        end

        #GET /cards
        paginate
        get "" do
          authenticate!
          @current_user.cards.page(params[:page])
        end

        #GET /cards/:id
        params do
          requires :id
        end
        get "/:id" do
          authenticate!
          @card = @current_user.cards.where(id: params[:id]).first
          if !@card.nil?
            @card
          else
            []
          end
        end

        #PUT /cards/:id
        params do
          requires :id
        end
        put "/:id" do
          authenticate!
          @card = @current_user.cards.where(id: params[:id]).first
          if !@card.nil?
            @card.update(params)
            if @card.valid?
              {status: 'success', formatted_name: @card.get_formatted_name, formatted_validate_date: @card.get_formatted_validate_date}
            else
              {status: 'failed', errors: @card.errors, errors_message: @card.errors.full_messages.join('<br>')}
            end
          else
            {status: 'failed', errors: 'Cartão não encontrado'}
          end
        end

        #DELETE /cards/:id
        params do
          requires :id
        end
        delete "/:id" do
          authenticate!
          @card = @current_user.cards.where(id: params[:id]).first
          if !@card.nil?
            if @card.destroy
              {status: 'success'}
            else
              {status: 'failed'}
            end
          else
            {status: 'failed', errors: 'Cartão não encontrado'}
          end
        end

      end

    end
  end
end