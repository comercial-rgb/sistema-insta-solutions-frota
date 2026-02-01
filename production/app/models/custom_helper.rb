class CustomHelper < ApplicationRecord

	# Retorna o texto da data formatado como desejado
	# type = 'date' ou 'datetime'
	# format = :default, :full ou qualquer outro especificado no arquivo de internacionalização
	def self.get_text_date(date, type, format)
		result = ''
		if !date.nil? && !date.blank? && !format.nil?
			if type == 'datetime'
				result = I18n.l date.to_datetime, format: format
			elsif type == 'date'
				result = I18n.l date.to_date, format: format
			end
		end
		return result
	end

	# Retorna o valor como moeda
	# value = valor numérico (0, 10, 23.42, ...)
	def self.to_currency(value)
		result = ''
		if !value.nil?
			result = ActionController::Base.helpers.number_to_currency(value)
		end
		return result
	end

	# Retorna o valor como precisão
	# value = valor numérico (0, 10, 23.42, ...)
	# precisão = 1, 2
	def self.to_precision(value, precision)
		result = ''
		if !value.nil?
			result = ActionController::Base.helpers.number_with_precision value, :precision => precision
		end
		return result
	end

	# Retorna valor numérico que está formatado em moeda
	def self.currency_to_value(value)
		value = value.to_s
		if value.include?('R$')
			if value.include?('.')
				value = value.gsub!('.', '')
			end
			if value.include?('R$')
				value = value.gsub!('R$', '')
			end
			if value.include?('%')
				value = value.gsub!('%', '')
			end
			if value.include?(',')
				value = value.gsub!(',', '.')
			end
			value = value.to_f
		end
		return value
	end

	# Retorna o valor como %
	# value = valor numérico (0, 10, 23.42, ...)
	# precision = valor numérico (0, 2, 3)
	def self.to_percentage(value, precision)
		result = ''
		if !value.nil?
			result = ActionController::Base.helpers.number_to_percentage(value, precision: precision)
		end
		return result
	end

	# Retorna o texto "Sim" ou "Não" baseado no parâmetro
	# value = true ou false
	def self.show_text_yes_no(value)
		result = ''
		if !value.nil?
			result = value ? I18n.t('model.yes') : I18n.t('model.no')
		end
		return result
	end

	# Retorna um array para selects com as opções "Sim" e "Não"
	def self.return_select_options_yes_no
		return [[I18n.t("model.yes"), 1],[I18n.t("model.no"), 0]]
	end

	# Retorna um array para selects com as opções "True" e "False"
	def self.return_select_options_true_false
		return [[I18n.t("model.yes"), true],[I18n.t("model.no"), false]]
	end

	# Retorna distância entre datas pela unidade desejada (:hours, :minutes, :days, :years, :months, etc)
	def self.distance_of_time_in(unit, from, to)
	  begin
	    diff = to - from
	    case unit.to_sym
	    when :seconds, :minutes, :hours
	      if 1.respond_to?(unit)
	        distance = diff / 1.send(unit)
	        return distance.to_f
	      else
	        Rails.logger.error "Unsupported unit: #{unit}"
	      end
	    when :months
	      days_in_month = 30.44 # Average days in a month
	      distance = diff / days_in_month
	      return distance.to_f
	    else
	      Rails.logger.error "Unsupported unit: #{unit}"
	    end
	  rescue NoMethodError => e
	    Rails.logger.error "Error calculating distance of time: #{e.message}"
	  end
	end

	# Retorna um array de anos para ser selecionado em um select
	def self.get_years(initial, final)
		array = []
		(initial..(final)).each do |i|
			array.push([i, i])
		end
		return array
	end

	# Retorna opções de meses para select
	def self.get_months_options
		return [
			["Janeiro", 1],
			["Fevereiro", 2],
			["Março", 3],
			["Abril", 4],
			["Maio", 5],
			["Junho", 6],
			["Julho", 7],
			["Agosto", 8],
			["Setembro", 9],
			["Outubro", 10],
			["Novembro", 11],
			["Dezembro", 12],
		]
	end

	# Retorna nome do mês pela posição
	def self.get_name_month_by_position(month)
		case month
		when 1
			return "Janeiro"
		when 2
			return "Fevereiro"
		when 3
			return "Março"
		when 4
			return "Abril"
		when 5
			return "Maio"
		when 6
			return "Junho"
		when 7
			return "Julho"
		when 8
			return "Agosto"
		when 9
			return "Setembro"
		when 10
			return "Outubro"
		when 11
			return "Novembro"
		when 12
			return "Dezembro"
		end
	end

	def self.url_for(object)
		if !object.nil?
			return Rails.application.routes.url_helpers.url_for(object)
		end
	end

	def self.show_svg(blob)
		blob.open do |file|
			raw file.read
		end
	end

	# Cor hexadecimal para RGBA
	def self.hex_color_to_rgba(hex, opacity)
		begin
			if hex =~ /^#...$/
				hex = hex.split(//).map { |single| single * 2 }.join[1..]
			end
			*rgb, alpha = hex.match(/^#(..)(..)(..)(..)?$/).captures.map { |hex_pair| hex_pair&.hex }
			# opacity = (alpha || 255) / 255.0
			"rgba(#{rgb.join(", ")}, #{opacity})"
		rescue Exception => e
			Rails.logger.error e.message
			Rails.logger.error "-- hex_color_to_rgba --"
		end
	end

	# Busca de idade por uma data
	def self.get_age(date)
		now = Time.now.utc.to_date
		now.year - date.year - ((now.month > date.month || (now.month == date.month && now.day >= date.day)) ? 0 : 1)
	end

	# Retorna informações do mês
	def self.get_current_month_data(current_date)
	    # Dia da semana do primeiro dia do mês
	    initial_week_day = (current_date.strftime('%w').to_i)
	    if initial_week_day == 6
	      # Sábado
	      if current_date.end_of_month.day == 31
	        quantity_weeks = 6
	      else
	        quantity_weeks = 5
	      end
	    elsif initial_week_day == 0
	      # Domingo
	      initial_week_day = 7
	      if current_date.end_of_month.day == 30 || current_date.end_of_month.day == 31
	        quantity_weeks = 6
	      else
	        quantity_weeks = 5
	      end
	    else
	      quantity_weeks = 5
	    end
	    final_month_day = (current_date.to_date.end_of_month).strftime('%d').to_i
	    return [initial_week_day, quantity_weeks, final_month_day]
	end

	# Retira caracteres especiais do texto
	def self.to_canonical(text)
		return text.gsub(/[áàâãä]/,'a').gsub(/[ÁÀÂÃÄ]/,'A')
	end

	def self.get_clean_text(text)
		result = ""
		if !text.nil? && !text.blank?
			result = text.gsub('.','')
			result = result.gsub(' ','')
			result = result.gsub('-','')
			result = result.gsub('/','')
			result = result.gsub(')','')
			result = result.gsub('(','')
		end
		return result
	end

	def self.attachment_to_base64(attachment)
		result = ""
		if !attachment.nil? && attachment.attached?
			begin
				img = URI.open(attachment.url)
				result = Base64.encode64(img.read).gsub("\n", "")
			rescue Exception => e
				result = ""
			end
		end
		return result
	end

	# Validação de e-mail
	def self.address_valid?(email)
		address = ValidEmail2::Address.new(email)
		return (address.valid? && address.valid_mx?)
	end

	# Retorna os dias da semana
	def self.get_week_days
		return [
			["Segunda-feira", 2, "S"],
			["Terça-feira", 3, "T"],
			["Quarta-feira", 4, "Q"],
			["Quinta-feira", 5, "Q"],
			["Sexta-feira", 6, "S"],
			["Sábado", 7, "S"],
			["Domingo", 1, "D"],
		]
	end

	# Gerando senha com 2 números, 2 letras maiúsculas, 2 letras minúsculas e 2 caracteres especiais
	def self.generate_valid_password
		number = ([*(48..57)]).sample(2).collect(&:chr)*""
		upper = ([*(65..90)]).sample(2).collect(&:chr)*""
		down = ([*(97..122)]).sample(2).collect(&:chr)*""
		special_character = ([*(59..64)]).sample(2).collect(&:chr)*""
		return (number + upper + down + special_character)
	end

	# Colocar em maiúsculo a primeira letra de cada palavra
	def self.titleize(text)
		nocaps = ["de", "do", "da"]
		upcases = []
		return text.split(" ").map { |word| nocaps.include?(word) ? word : (upcases.include?(word.downcase) ? word.upcase : word.capitalize ) }.join(" ")
	end

	# Mascarar o CPF
	def self.mask_cpf(cpf)
		if cpf.match?(/^\d{11}$/)
			cpf.gsub(/(\d{3})(\d{3})(\d{3})(\d{2})/, '\1.***.***-\4')
		else
			cpf.gsub(/\.(\d{3})\.(\d{3})-/, '.***.***-')
		end
	end

end
