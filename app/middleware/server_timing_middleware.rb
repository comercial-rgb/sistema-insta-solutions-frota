class ServerTimingMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status, headers, body = @app.call(env)
    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round(1)

    headers['Server-Timing'] = "app;desc=\"Rails\";dur=#{duration_ms}"
    headers['X-Response-Time'] = "#{duration_ms}ms"

    [status, headers, body]
  rescue => e
    Rails.logger.error "[ServerTiming] #{e.class}: #{e.message}"
    raise
  end
end
