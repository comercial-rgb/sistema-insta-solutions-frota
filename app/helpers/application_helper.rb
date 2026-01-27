module ApplicationHelper

	def controller?(*controller)
		controller.include?(params[:controller])
	end

	def action?(*action)
		action.include?(params[:action])
	end

	def is_current_page?(page)
		request.fullpath == page
	end

	def contains_current_page?(page)
		request.fullpath.include?(page)
	end

	# Formatando o site para ser redirecionado corretamente
	def format_site_http(link)
		result = ''
		if !link.nil? && !link.blank?
			result = link.gsub('http://', '')
			result = result.gsub('https://','')
			# formato que deve ser colocado no front: "http://#{format_site_http(link)}"
		end
		return result
	end

	# Remove todos os caracteres especiais (máscara) de um telefone
	def format_phone(phone)
		phone.gsub(/[^\d]/, '')
	end

	# Monta uma tag <a> já no formato para telefones
	def tel_to(body, phone, html_options = {})
		phone = 'tel:0' + format_phone(phone)
		link_to(body, phone, html_options)
	end

	# Monta uma tag <a> já no formato para e-mails
	def mail_to(body, mail, html_options = {})
		final_mail = 'mailto:' + mail
		link_to(body, final_mail, html_options)
	end

	# Montar uma tag <a> já no formato de abrir o WhatsApp
	def whatsapp_to(body, phone, html_options = {})
		phone = 'https://api.whatsapp.com/send?phone=55' + format_phone(phone)
		link_to(body, phone, html_options)
	end

	def safe_utf8(text)
		text.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
	end

	# Método para retornar a classe correta para renderizar o
	# "toast" do bootstrap de forma customizada
	def flash_class(level)
		case level
		when 'notice' then "bg-info text-white"
		when 'success' then "bg-success text-white"
		when 'error' then "bg-danger text-white"
		when 'alert' then "bg-warning text-dark"
		end
	end

	# Método para retornar o título correto a ser atribuído ao
	# renderizar o "toast" do bootstrap
	def flash_title(level)
		case level
		when 'notice' then 'Informação'
		when 'success' then 'Sucesso'
		when 'error' then 'Erro'
		when 'alert' then 'Atenção'
		end
	end

	# Retorna uma string sem o final a partir de um determinado caracter
	#
	# Exemplo:
	#  remove_after_char 'https://www.site.com.br/imagem?12345', '?'
	#
	# Vai retornar:
	#  'https://www.site.com.br/imagem'
	def remove_after_char(string, char)

		# Pego o índice que a o caracter está
		char_index = string.index(char)

		# Subtrai 1 para que pegar o íncide a ponto de remover o próprio caracter também seja removido
		char_index = char_index - 1;

		# Retorno a string sem o próprio caracter e tudo que tem para frente
		return string.slice(0..char_index)
	end

	# <iframe
	# src="<%= youtube_embed(youtube_link) %>"
	# title="YouTube video player"
	# frameborder="0"
	# allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen>
	# </iframe>
	# Convertendo link do youtube para embed
	def youtube_embed(youtube_url)
		begin
			if youtube_url[/youtu\.be\/([^\?]*)/]
				youtube_id = $1
			else
				youtube_url[/^.*((v\/)|(embed\/)|(watch\?))\??v?=?([^\&\?]*).*/]
				youtube_id = $5
			end
			return 'https://www.youtube.com/embed/'+youtube_id
		rescue Exception => e
			return ''
		end
	end

	def get_head_title
		result = t('session.project')
		if !@system_configuration.nil? && !@system_configuration.page_title.blank?
			result = @system_configuration.page_title
		end
		return result
	end

	def get_head_description
		result = t('session.project')
		if !@system_configuration.nil? && !@system_configuration.page_description.blank?
			result = @system_configuration.page_description
		end
		return result
	end

	def get_current_id_google_analytics
		result = ''
		if !@system_configuration.nil? && !@system_configuration.id_google_analytics.blank?
			result = @system_configuration.id_google_analytics
		end
		return result
	end

	# Removendo todos os caracteres especiais de uma string (caracteres e acentuação)
	def removing_special_characters(string)
		result = ''
		if !string.nil? && !string.blank?
			result = I18n.transliterate(string)
		end
		return result
	end

	def show_svg(blob)
    blob.open do |file|
      raw file.read
    end
  end

  def hide_filter?(filter)
  	result = false
  	if filter.name == :ownertable_type || filter.name == :ownertable_id || filter.name == :address_area_id || filter.name == :page_title
  		result = true
  	end
  	return result
  end

  def is_current_root_path?
  	return current_page?('/') # || current_page?(root_url)
  end

  VIMEO_REGEX = %r(^https?:\/\/(?:.*?)\.?(vimeo)\.com\/(\d+)\/?([a-zA-Z0-9]+)?.*$)

	def find_vimeo_id url
		url     = sanitize url
		matches = VIMEO_REGEX.match url.to_str
		matches if matches
	end

	# <%= get_vimeo_iframe(video_link, 640, 360, 0, background, false) %>
	def get_vimeo_iframe vimeo_id, width, height, muted, background, pip
		begin
			# if Rails.env.development?
			# 	vimeo_id = "89684365"
			# 	# vimeo_id = "810735707"
			# end
			if !vimeo_id.nil? && !vimeo_id.blank?
				if !vimeo_id.nil?
					uri      = "https://vimeo.com/api/oembed.json?url=https%3A//vimeo.com/#{ vimeo_id[2] }/#{ vimeo_id[3] }/&width=#{ width }&height=#{ height }&muted=#{muted}&background=#{background}&allow='autoplay'&pip=#{pip}"
					response = Net::HTTP.get( URI.parse( uri ))
					json     = JSON.parse response
					json['html'].html_safe
				end
			end
		rescue Exception => e
			Rails.logger.error e.message
			return nil
		end
	end

	def current_controller_name
    controller_name
  end

  def current_action_name
    action_name
  end

  def ensure_custom_favicon(size)
    favicon_path = "/favicon/custom/favicon-#{size}.png"

    # Check if file exists in the public folder
    if File.exist?(Rails.root.join("public#{favicon_path}"))
      return favicon_path
    end

    # Trigger processing job if missing
    system_config = SystemConfiguration.first
    if system_config&.favicon&.attached?
      ProcessFaviconJob.perform_later(system_config.id)
      return favicon_path
    end

    # Return a simple data URI as fallback to avoid asset pipeline errors
    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
  end

end

# End of file application_helper.rb
# Path: ./app/helpers/application_helper.rb
