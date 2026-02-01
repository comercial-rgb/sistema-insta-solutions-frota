class ApplicationMailer < ActionMailer::Base
	default from: I18n.t('session.project')+' <comercial@instasolutions.com.br>'
end
