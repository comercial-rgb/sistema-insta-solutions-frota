#!/usr/bin/env puma
# =========================================================
# Puma Configuration
# =========================================================

# Threads
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Workers (use 0 for development)
workers ENV.fetch("WEB_CONCURRENCY") { 0 }

# Port
port ENV.fetch("PORT") { 3000 }

# Environment
environment ENV.fetch("RAILS_ENV") { "development" }

# PID
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Plugin
plugin :tmp_restart
