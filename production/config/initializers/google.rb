# Setup global parameters
GoogleMapsService.configure do |config|
  config.key = ENV['GOOGLE_GEOLOCATION_API']
  config.retry_timeout = 20
  config.queries_per_second = 10
end