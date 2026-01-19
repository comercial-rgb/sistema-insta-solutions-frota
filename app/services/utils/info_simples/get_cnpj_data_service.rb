module Utils
  module InfoSimples
    class GetCnpjDataService < BaseService

      # {
      #   "code": 200,
      #   "code_message": "A requisição foi processada com sucesso.",
      #   "header": {
      #     "api_version": "v2",
      #     "api_version_full": "2.2.4-20230217172654",
      #     "product": "Consultas",
      #     "service": "receita-federal/cnpj",
      #     "parameters": {
      #       "cnpj": "23573024000135"
      #     },
      #     "client_name": "Unica Comercio De Artigos De Decoracao Ltda",
      #     "token_name": "Unica Comercio De Artigos De Decoracao Ltda",
      #     "billable": true,
      #     "price": "0.2",
      #     "requested_at": "2023-02-21T15:40:40.000-03:00",
      #     "elapsed_time_in_milliseconds": 1036,
      #     "remote_ip": "201.3.251.235",
      #     "signature": "U2FsdGVkX1+2er29m914dwFeCR1MVXYTKdNcM9DUSLxFA7aVa2vqI6GMc2OfdYKq/eGwRQ+ntXU7n2XygN9XCg=="
      #   },
      #   "data_count": 1,
      #   "data": [
      #     {
      #       "abertura_data": "29/10/2015",
      #       "atividade_economica": "63.19-4-00 - Portais, provedores de conteúdo e outros serviços de informação na internet",
      #       "atividade_economica_secundaria": "62.01-5-01 - Desenvolvimento de programas de computador sob encomenda*",
      #       "atividade_economica_secundaria_lista": [
      #         "62.01-5-01 - Desenvolvimento de programas de computador sob encomenda*"
      #       ],
      #       "capital_social": "10000.00",
      #       "cnpj": "23.573.024/0001-35",
      #       "consulta_datahora": "21/02/2023 15:40:40",
      #       "efr": "*****",
      #       "email": "ANDRE.SULIVAM@SULIVAMIT.COM.BR",
      #       "endereco_bairro": "SANTA MARIA",
      #       "endereco_cep": "32.240-180",
      #       "endereco_complemento": "LOJA A",
      #       "endereco_logradouro": "R INDUSTRIAL",
      #       "endereco_municipio": "CONTAGEM",
      #       "endereco_numero": "516",
      #       "endereco_uf": "MG",
      #       "licenciamento_dispensado": [

      #       ],
      #       "matriz_filial": "MATRIZ",
      #       "natureza_juridica": "2062 - SOCIEDADE EMPRESARIA LIMITADA",
      #       "natureza_juridica_codigo": "2062",
      #       "nome_fantasia": "SULIVAM IT SOLUTIONS",
      #       "normalizado_abertura_data": "29/10/2015",
      #       "normalizado_capital_social": 10000.0,
      #       "normalizado_cnpj": "23573024000135",
      #       "normalizado_consulta_datahora": "21/02/2023 15:40:40",
      #       "normalizado_endereco_cep": "32240180",
      #       "normalizado_situacao_cadastral_data": "29/10/2015",
      #       "normalizado_situacao_especial_data": "",
      #       "origem": "mobile",
      #       "porte": "",
      #       "qsa": [
      #         {
      #           "nome": "ANDRE SULIVAM RAMOS DE SOUZA",
      #           "qualificacao": "Sócio-Administrador",
      #           "nome_representante_legal": "",
      #           "qualificacao_representante_legal": "",
      #           "pais_origem": ""
      #         }
      #       ],
      #       "razao_social": "SULIVAM SERVICOS DE TECNOLOGIA DA INFORMACAO LTDA",
      #       "situacao_cadastral": "ATIVA",
      #       "situacao_cadastral_data": "29/10/2015",
      #       "situacao_cadastral_observacoes": "",
      #       "situacao_especial": "********",
      #       "situacao_especial_data": "********",
      #       "telefone": "31-93192163",
      #       "site_receipt": "https://storage.googleapis.com/infosimples-api-tmp-files/api/receita-federal/cnpj/20230221154040/NtWA7sBsM_Z3E9NC8rcVsBl52ryHoRXE/dc4bf0fd3890b556499a62e49185f815_0_w9Q.html"
      #     }
      #   ],
      #   "errors": [

      #   ],
      #   "site_receipts": [
      #     "https://storage.googleapis.com/infosimples-api-tmp-files/api/receita-federal/cnpj/20230221154040/NtWA7sBsM_Z3E9NC8rcVsBl52ryHoRXE/dc4bf0fd3890b556499a62e49185f815_0_w9Q.html"
      #   ]
      # }
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
          Rails.logger.info "aquo"
          args = {
            'cnpj'    => @cnpj,
            'token'   => @token_api,
            'timeout' => 300
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
