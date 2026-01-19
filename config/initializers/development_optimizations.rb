# Otimizações para ambiente de desenvolvimento Windows
# Melhora performance e reduz logs verbosos

if Rails.env.development?
  # Reduz logs do ActiveRecord (apenas erros e avisos)
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.logger.level = Logger::WARN
  end

  # Reduz logs de assets
  Rails.application.config.assets.quiet = true

  # Desabilita logs de cache de fragmentos
  Rails.application.config.action_controller.enable_fragment_cache_logging = false

  # Melhora performance de autoload no Windows
  Rails.autoloaders.log! if ENV['DEBUG_AUTOLOAD']
end
