module Utils
  module InfoSimples
    class GetVehicleDataService < BaseService

      def initialize(cnpj)
        @cnpj = cnpj
      end

      def call
        return [nil, I18n.t("api.invalid_access_data"), nil] if invalid?
        define_environment_data
        get_result
      end

      private

      def invalid?
        service = Utils::InfoSimples::AuthService.new
        transaction = service.call
        return transaction.nil? || @cnpj.nil? || @cnpj.blank? || !CNPJ.valid?(@cnpj)
      end

      def define_environment_data
        service = Utils::InfoSimples::AuthService.new
        transaction = service.call
        @url = transaction[0]
        @token_api = transaction[1]
      end

      def get_result
        begin
          args = {
            'placa'       => "VALOR_DO_PARAMETRO_PLACA",
            'renavam'     => "VALOR_DO_PARAMETRO_RENAVAM",
            'cnpj'        => "VALOR_DO_PARAMETRO_CNPJ",
            'login_cpf'   => "VALOR_DO_PARAMETRO_LOGIN_CPF",
            'login_senha' => "VALOR_DO_PARAMETRO_LOGIN_SENHA",
            'pkcs12_cert' => AES256.encrypt(Base64.strict_encode64(File.open("certificado.pfx", "rb").read), "INFORME_A_CHAVE_DE_CRIPTOGRAFIA"),
            'pkcs12_pass' => AES256.encrypt("SENHA_DO_CERTIFICADO", "INFORME_A_CHAVE_DE_CRIPTOGRAFIA"),
            'token'       => "INFORME_AQUI_O_TOKEN_DA_CHAVE_DE_ACESSO",
            'timeout'     => 300
          }
          uri = URI(@url+"/consultas/receita-federal/cnpj")
          req = Net::HTTP::Post.new(uri)
          req.set_form(args)
          res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
            http.request(req)
          end
          response = JSON.parse(res.body)
          case response['code']
          when 200
            return [true, '', response]
          when 600..799
            mensagem = "Resultado sem sucesso. Leia abaixo para saber mais:\n"
            mensagem += "Código: #{response['code']} (#{response['code_message']})\n"
            mensagem += response['errors'].join('; ')
            return [false, mensagem, nil]
          end
        rescue Exception => e
          return [nil, e.message, nil]
        end
      end

    end
  end
end
