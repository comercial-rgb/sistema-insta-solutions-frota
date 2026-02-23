class ProcessFaviconJob < ApplicationJob
  queue_as :default

  def perform(system_configuration_id)
    # Favicons pré-gerados são deployados em public/favicon/custom/
    # Não é necessário processamento em runtime (ImageMagick não é mais necessário)
    Rails.logger.info "ProcessFaviconJob: ignorado — usando favicons pré-gerados"
  end
end
