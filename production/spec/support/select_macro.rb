module SelectMacro

	def select_personalized(item_text, options)
		field = find_field(options[:from], :visible => false)
		find("##{field[:id]}_chosen").click
		find("##{field[:id]}_chosen ul.chosen-results li", :text => item_text).click		
	end
	
end