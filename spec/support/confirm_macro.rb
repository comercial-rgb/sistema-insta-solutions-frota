module ConfirmMacro
	def confirm
		sleep 1
		page.driver.browser.switch_to.alert.accept rescue Selenium::WebDriver::Error::NoAlertOpenError
		sleep 1
	end
end
