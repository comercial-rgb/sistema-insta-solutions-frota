class ApplicationMailer < ActionMailer::Base
	default from: I18n.t('session.project')+' <noreply@frotainstasolutions.com.br>'
end
