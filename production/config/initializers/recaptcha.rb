Recaptcha.configure do |config|
  config.site_key  = ENV['GOOGLE_SITE_KEY']
  config.secret_key = ENV['GOOGLE_SECRET_KEY']
end