#!/usr/bin/env puma
# =========================================================
# Puma Configuration - Production
# =========================================================
# Frota Insta Solutions
# app.frotainstasolutions.com.br
# =========================================================

# Diretório da aplicação
app_dir = '/var/www/frotainstasolutions/production'
directory app_dir

# Rackup
rackup "#{app_dir}/config.ru"

# Ambiente
environment 'production'

# Tag para identificar o processo
tag 'frotainstasolutions'

# Arquivos PID e state
pidfile "#{app_dir}/tmp/pids/puma.pid"
state_path "#{app_dir}/tmp/pids/puma.state"

# Logs
stdout_redirect(
  "#{app_dir}/log/puma_access.log",
  "#{app_dir}/log/puma_error.log",
  true
)

# Threads por worker
# Mínimo: 0, Máximo: 16
# Para servidor com 4GB RAM: threads 2, 8
# Para servidor com 8GB RAM: threads 4, 16
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# Workers (processos)
# Regra: 1 worker por core de CPU
# Servidor com 2 cores: workers 2
# Servidor com 4 cores: workers 4
workers_count = ENV.fetch("WEB_CONCURRENCY") { 2 }
workers workers_count

# Preload da aplicação
# Carrega código antes de fazer fork dos workers
# Economiza memória RAM
preload_app!

# Bind - Socket Unix (melhor performance que TCP)
bind "unix://#{app_dir}/tmp/sockets/puma.sock"

# Alternativa: Bind TCP (se preferir)
# bind 'tcp://0.0.0.0:3000'

# Porta (se usar TCP)
# port ENV.fetch("PORT") { 3000 }

# Daemonize (rodar em background)
# Não usar quando gerenciado por systemd
# daemonize false

# Callbacks

# Antes de fazer fork dos workers
before_fork do
  puts "Puma master process about to fork workers..."
  
  # Fechar conexões do banco antes de fork
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

# Callback executado no master após fazer fork
on_worker_boot do
  puts "Puma worker #{Process.pid} booting..."
  
  # Reconectar ao banco em cada worker
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
  
  # Limpar cache se necessário
  Rails.cache.clear if defined?(Rails)
end

# Callback ao reiniciar
on_restart do
  puts 'Puma master process restarting...'
  
  # Atualizar Gemfile
  ENV["BUNDLE_GEMFILE"] = "#{app_dir}/Gemfile"
end

# Worker timeout
# Tempo máximo para worker responder (segundos)
worker_timeout 60

# Worker shutdown timeout
# Tempo para worker finalizar gracefully antes de kill -9
worker_shutdown_timeout 30

# Nakayoshi fork
# Otimização de memória para Ruby 2.7+
# nakayoshi_fork true

# Plugin: para tmp/restart.txt
plugin :tmp_restart

# Plugin: systemd (se usar systemd)
# activate_control_app
