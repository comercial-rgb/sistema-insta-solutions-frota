module Api
  module V2
    class Contact < Grape::API
      resource :contact do
        before { authenticate! }

        desc 'Enviar mensagem de contato/suporte'
        params do
          requires :subject, type: String
          requires :message, type: String
          optional :category, type: String, values: %w[suporte duvida reclamacao sugestao outro]
        end
        post do
          user = current_user

          SiteContact.create!(
            name: user.name,
            email: user.email,
            phone: user.cellphone || user.phone,
            subject: params[:subject],
            message: params[:message],
            site_contact_subject_id: nil
          )

          { message: 'Mensagem enviada com sucesso. Retornaremos em breve.' }
        end

        desc 'Informações de contato da empresa'
        get 'info' do
          {
            company: 'Insta Solutions',
            email: 'contato@instasolutions.com.br',
            phone: '(11) 0000-0000',
            whatsapp: '(11) 90000-0000',
            address: 'Endereço da empresa',
            hours: 'Segunda a Sexta, 8h às 18h'
          }
        end
      end
    end
  end
end
