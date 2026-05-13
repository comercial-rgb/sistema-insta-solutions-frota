# frozen_string_literal: true

# Rate limiting for API auth (see https://github.com/rack/rack-attack)
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

class Rack::Attack
  LOGIN_LIMIT = Rails.env.production? ? 20 : 200
  LOGIN_PERIOD = 1.minute

  RECOVER_LIMIT = Rails.env.production? ? 8 : 100
  RECOVER_PERIOD = 1.hour

  throttle('api/v1/auth/login/ip', limit: LOGIN_LIMIT, period: LOGIN_PERIOD) do |req|
    req.ip if req.post? && req.path == '/api/v1/auth/login'
  end

  throttle('web/sessions/ip', limit: LOGIN_LIMIT, period: LOGIN_PERIOD) do |req|
    req.ip if req.post? && req.path == '/sessions'
  end

  throttle('api/v1/auth/recover_pass/ip', limit: RECOVER_LIMIT, period: RECOVER_PERIOD) do |req|
    req.ip if req.post? && req.path == '/api/v1/auth/recover_pass'
  end

  self.throttled_responder = lambda do |request|
    match_data = request.env['rack.attack.match_data']
    headers = {
      'Content-Type' => 'application/json',
      'Retry-After' => match_data[:period].to_s
    }
    body = { status: 'failed', message: 'Muitas tentativas. Aguarde e tente novamente.' }.to_json
    [429, headers, [body]]
  end
end
