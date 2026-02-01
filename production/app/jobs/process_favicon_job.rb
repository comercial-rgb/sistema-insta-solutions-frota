require 'mini_magick'

class ProcessFaviconJob < ApplicationJob
  queue_as :default

  def perform(system_configuration_id)
    system_configuration = SystemConfiguration.find_by(id: system_configuration_id)
    return unless system_configuration&.favicon&.attached?

    sizes = ["57x57", "60x60", "72x72", "76x76", "114x114", "120x120", "144x144", "152x152", "180x180", "192x192", "32x32", "96x96", "16x16"]
    favicon_folder = Rails.root.join("public/favicon/custom")
    FileUtils.mkdir_p(favicon_folder) unless File.directory?(favicon_folder)

    # Download original favicon from Active Storage
    blob = system_configuration.favicon.blob
    original_path = Rails.root.join("tmp", "favicon_original.#{blob.filename.extension}")
    File.open(original_path, 'wb') { |file| file.write(blob.download) }

    # Process each size
    sizes.each do |size|
      favicon_path = favicon_folder.join("favicon-#{size}.png")
      next if File.exist?(favicon_path) # Skip if already exists

      image = MiniMagick::Image.open(original_path)
      image.resize "#{size.split('x').first}x#{size.split('x').last}"
      image.write favicon_path
    end

    # Clean up temp file
    File.delete(original_path) if File.exist?(original_path)
  end
end
