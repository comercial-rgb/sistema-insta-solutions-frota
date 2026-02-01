##
# Módulo dedicado a montar as URLs para compartilhamentos sociais e correlatos
module ShareHelper

    # Monta uma tag <a> já no formato para compartilhar no Facebook
    def facebook_to(body = 'Facebook', url = nil, html_options = {})
        share_to :facebook, body, url, html_options
    end

    # Monta uma tag <a> já no formato para compartilhar no Pinterest
    def pinterest_to(body = 'Pinterest', url = nil, html_options = {})
        share_to :pinterest, body, url, html_options
    end

    # Monta uma tag <a> já no formato para compartilhar no Twitter
    def twitter_to(body = 'Twitter', url = nil, html_options = {})
        share_to :twitter, body, url, html_options
    end

    private
        def share_to(type, body, url, html_options = {})
            html_options[:target] = '_blank'
            url = request.original_url if url.nil?
            types = {
                :facebook  => "https://www.facebook.com/sharer/sharer.php?u=#{url}",
                :pinterest => "http://pinterest.com/pin/create/link/?url=#{url}",
                :twitter   => "http://twitter.com/share?url=#{url}"
            }

            link_to(body, types[type], html_options)
        end
end

# End of file share_helper.rb
# Path: ./app/helpers/share_helper.rb