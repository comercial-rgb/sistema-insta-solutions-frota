module Utils
  module InfoSimples
    class AuthService < BaseService

      def initialize
        @url = nil
        @token_api = nil
      end

      def call
        return nil if invalid?
        define_environment_data
        return_environment_data
      end

      private

      def invalid?
        if Rails.env.development?
          return (ENV['AUTH_SERVICE_DESENV_URL'].nil? || ENV['AUTH_SERVICE_DESENV_URL'].blank?) || (ENV['AUTH_SERVICE_DESENV_TOKEN_API'].nil? || ENV['AUTH_SERVICE_DESENV_TOKEN_API'].blank?)
        elsif Rails.env.production?
          return (ENV['AUTH_SERVICE_PRODUCTION_URL'].nil? || ENV['AUTH_SERVICE_PRODUCTION_URL'].blank?) || (ENV['AUTH_SERVICE_PRODUCTION_TOKEN_API'].nil? || ENV['AUTH_SERVICE_PRODUCTION_TOKEN_API'].blank?)
        end
      end

      def define_environment_data
        if Rails.env.development?
          @url = ENV['AUTH_SERVICE_DESENV_URL']
          @token_api = ENV['AUTH_SERVICE_DESENV_TOKEN_API']
        elsif Rails.env.production?
          @url = ENV['AUTH_SERVICE_PRODUCTION_URL']
          @token_api = ENV['AUTH_SERVICE_PRODUCTION_TOKEN_API']
        end
      end

      def return_environment_data
        return [@url, @token_api]
      end

    end
  end
end
