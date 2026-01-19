require 'rufus-scheduler'

ENV['TZ'] = 'America/Sao_Paulo'

# Se necessitar de garantir apenas 1 execução por vez (necessário no servidor criar o arquivo .rufus-scheduler.lock na raiz do projeto e dar permissão de escrita)
# s = Rufus::Scheduler.singleton(lockfile: '.rufus-scheduler.lock')

s = Rufus::Scheduler.singleton(lockfile: ".rufus-scheduler.lock")

unless s.down?
	# Todo dia 03:00
	s.cron '00 03 * * *' do
		# Banner.routine_inactive_banners
		# Subscription.routine_cancel_subscriptions
		# Subscription.routine_renew_subscriptions
		# Subscription.cancel_manually_plan
	end

	# De hora em hora
	s.every '1h', :first_in => 5 do
		if Rails.env.development?
			# Blog.routine_active_blogs
			# Subscription.routine_cancel_subscriptions
			# Subscription.routine_renew_subscriptions
			# Subscription.cancel_manually_plan
		end
	end

	# Em 1 minuto (uma vez)
	s.in '1m' do
	end

	# Todo dia 01 do mês às 05:00
	s.cron '00 05 01 * *' do
	end
end
