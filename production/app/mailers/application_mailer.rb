class ApplicationMailer < ActionMailer::Base
	default from: I18n.t('session.project')+' <contato@sulivam.com.br>'
end
