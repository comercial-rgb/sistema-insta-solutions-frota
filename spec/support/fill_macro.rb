module FillMacro
	
	def fill_in(locator, options={})
		field = page.find_field(locator)

		if field["data-mask"]
			return page.execute_script %{ $("##{field[:id]}").val("#{options.fetch(:with)}"); }
		end

		super
	end

	def fill_in_ckeditor(locator, opts)
		content = opts.fetch(:with).to_json 
		page.execute_script <<-SCRIPT
		CKEDITOR.instances['#{locator}'].setData(#{content});
		$('textarea##{locator}').text(#{content});
		SCRIPT
	end

	def fill_in_mask(locator, opts)
		content = opts.fetch(:with).to_json 
		find(:css, "input[id$='#{locator}']").set(content)
	end

end