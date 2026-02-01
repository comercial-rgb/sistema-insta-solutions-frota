require '/var/www/frotainstasolutions/production/config/environment'
user = User.first
user.update_column(:recovery_token, SecureRandom.urlsafe_base64)
user.reload
puts "Token: #{user.recovery_token}"
puts "Email: #{user.email}"
NotificationMailer.forgot_password(user, SystemConfiguration.first).deliver_now
puts "Enviado!"
