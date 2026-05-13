class SafeFileValidator < ActiveModel::EachValidator
  PROFILES = {
    image: {
      content_types: %w[image/jpeg image/png image/gif image/webp image/svg+xml],
      label: 'imagem (JPEG, PNG, GIF, WebP, SVG)'
    },
    document: {
      content_types: %w[
        image/jpeg image/png image/gif image/webp application/pdf
        application/vnd.openxmlformats-officedocument.wordprocessingml.document
        application/msword
      ],
      label: 'imagem, PDF ou Word (.docx/.doc)'
    },
    invoice: {
      content_types: %w[
        image/jpeg image/png application/pdf
        text/xml application/xml
      ],
      label: 'imagem, PDF ou XML (nota fiscal eletrônica)'
    },
    media: {
      content_types: %w[
        image/jpeg image/png image/gif image/webp
        video/mp4 video/quicktime video/x-msvideo video/mpeg
        audio/mpeg audio/ogg audio/wav audio/x-wav
        application/pdf
      ],
      label: 'imagem, vídeo, áudio ou PDF'
    },
    certificate: {
      extensions: %w[.pfx .p12 .pem .cer .crt],
      label: 'certificado digital (PFX, P12, PEM, CER, CRT)'
    }
  }.freeze

  BLOCKED_EXTENSIONS = %w[
    .exe .php .php3 .php4 .php5 .phtml .phar
    .jsp .jspx .asp .aspx .axd .asx .ascx .ashx
    .sh .bash .zsh .csh .fish .bat .cmd .ps1 .psm1 .psd1
    .vbs .vbe .js .jse .wsf .wsh .msc .msi .msp .mst
    .rb .py .pl .cgi .lua .go .jar .war .ear .class
    .htaccess .htpasswd .config .cfg .ini .env
    .dll .so .dylib .sys .drv .com .scr .hta
  ].freeze

  def validate_each(record, attribute, value)
    return unless value.attached?

    profile_name = options[:profile] || :document
    profile = PROFILES[profile_name]
    blobs = value.respond_to?(:blobs) ? value.blobs : [value.blob]

    blobs.each do |blob|
      ext = File.extname(blob.filename.to_s).downcase
      ct  = blob.content_type.to_s.downcase.split(';').first.strip

      if BLOCKED_EXTENSIONS.include?(ext)
        record.errors.add(attribute, :blocked_extension,
          message: "contém extensão bloqueada (#{ext}). Arquivos executáveis não são permitidos.")
        next
      end

      if profile_name == :certificate
        unless profile[:extensions].include?(ext)
          record.errors.add(attribute, :invalid_certificate,
            message: "deve ser um #{profile[:label]}. Recebido: #{ext.presence || 'sem extensão'}.")
        end
        next
      end

      unless profile[:content_types].include?(ct)
        record.errors.add(attribute, :invalid_content_type,
          message: "deve ser #{profile[:label]}. Tipo recebido: #{ct.presence || 'desconhecido'}.")
      end
    end
  end
end
