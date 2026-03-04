#!/usr/bin/env puma
# =========================================================
# Puma Configuration
# =========================================================
# Em PRODUCTION, usa config/puma/production.rb automaticamente.
# Este arquivo é para DEVELOPMENT/TEST apenas.
# =========================================================

current_env = ENV.fetch("RAILS_ENV") { "development" }

# Se estiver em produção, carrega a config específica
if current_env == "production"
  puma_production_config = File.expand_path("puma/production.rb", __dir__)
  if File.exist?(puma_production_config)
    # A config de produção será carregada por: puma -C config/puma/production.rb
    # Se alguém iniciar com puma -C config/puma.rb em produção,
    # redireciona para a config correta
    puts "[Puma] Ambiente production detectado. Use: puma -C config/puma/production.rb"
    puts "[Puma] Carregando config de produção automaticamente..."

    # Configuração de fallback para produção
    app_dir = ENV.fetch("APP_DIR") { "/var/www/frotainstasolutions/production" }

    directory app_dir
    environment "production"
    tag "frotainstasolutions"

    pidfile "#{app_dir}/tmp/pids/puma.pid"
    state_path "#{app_dir}/tmp/pids/puma.state"

    stdout_redirect(
      "#{app_dir}/log/puma_access.log",
      "#{app_dir}/log/puma_error.log",
      true
    )

    threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
    threads threads_count, threads_count

    workers ENV.fetch("WEB_CONCURRENCY") { 2 }
    preload_app!

    # BIND VIA UNIX SOCKET (Nginx depende disto!)
    bind "unix://#{app_dir}/tmp/sockets/puma.sock"

    before_fork do
      ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
    end

    on_worker_boot do
      ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
    end

    on_restart do
      ENV["BUNDLE_GEMFILE"] = "#{app_dir}/Gemfile"
    end

    worker_timeout 60
    worker_shutdown_timeout 30
    plugin :tmp_restart
  end
else
  # =========================================================
  # Development / Test
  # =========================================================
  max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
  min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
  threads min_threads_count, max_threads_count

  workers ENV.fetch("WEB_CONCURRENCY") { 0 }
  port ENV.fetch("PORT") { 3000 }
  environment current_env
  pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }
  plugin :tmp_restart
end
