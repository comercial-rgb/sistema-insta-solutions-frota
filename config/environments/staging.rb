# Ambiente de Staging/Teste
# Este ambiente se comporta como produção, mas com algumas facilidades para debugging

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings similar to production
  config.cache_classes = true
  config.eager_load = true
  
  # Show full error reports (diferente de production)
  config.consider_all_requests_local = true
  
  # Caching como em produção
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = true
  
  # Assets
  config.assets.compile = false
  config.assets.digest = true
  
  # Storage
  config.active_storage.service = :local
  
  # Force SSL (opcional - descomente se usar HTTPS)
  # config.force_ssl = true
  
  # Logging
  config.log_level = :debug
  config.log_tags = [ :request_id ]
  
  # Mailer (não enviar emails de verdade em staging)
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = false
  config.action_mailer.default_url_options = { host: ENV['STAGING_HOST'] || 'staging.example.com' }
  
  # Active Record
  config.active_record.dump_schema_after_migration = false
  
  # Inserts middleware to report failures
  config.active_support.report_deprecations = true
  
  # Uncomment if you wish to allow Action Cable access from any origin
  # config.action_cable.disable_request_forgery_protection = true
end
