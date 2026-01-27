Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Compress JavaScript.
  config.assets.js_compressor = :terser

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true
  
  # Desabilitar cache de assets para evitar problemas de permissão no Windows
  config.assets.configure do |env|
    env.cache = ActiveSupport::Cache.lookup_store(:null_store)
  end

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Storage local para desenvolvimento (sem AWS S3)
  config.active_storage.service = :local
  # Credenciais da Amazon AWS S3 (comentado para desenvolvimento local)
  # config.active_storage.service = :amazon  
  # config.paperclip_defaults = {
  #   :storage => :s3,
  #   :s3_host_name => 's3-sa-east-1.amazonaws.com',
  #   :s3_protocol => 'https',
  #   :s3_region => 'sa-east-1',
  #   s3_credentials: {
  #     bucket: 'sistema-insta-solutions-development',
  #     access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  #     secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  #   }
  # }

  config.action_mailer.default_url_options = { :host => "localhost:3000" }
  Rails.application.routes.default_url_options[:host] = "localhost:3000"
  
  # ActiveStorage URL options
  config.after_initialize do
    ActiveStorage::Current.url_options = { host: 'localhost', port: 3000, protocol: 'http' }
  end
  
  # Websocket
  config.action_cable.allowed_request_origins = [
    /http:\/\/*/,
    /https:\/\/*/,
    /file:\/\/*/,
    'file://',
    /ionic:\/\/*/,
    'ionic://',
    /capacitor:\/\/*/,
    'capacitor://', 
    nil
  ]

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address => ENV['SMTP_ADDRESS'],
    :port => ENV['SMTP_PORT'],
    :user_name => ENV['SMTP_USERNAME'],
    :password => ENV['SMTP_PASSWORD'],
    :authentication => :login,
    :enable_starttls_auto => true
  }
  
end
