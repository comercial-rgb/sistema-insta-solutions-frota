class Service < ApplicationRecord
  include PadronizaNome

  after_initialize :default_values
  before_validation :padronizar_nome_service

  default_scope {
    with_attached_image
    .includes(:category)
    .order(:name)
  }

  scope :by_id, lambda { |value| where("services.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_provider_id, lambda { |value| where("services.provider_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_name, lambda { |value| where("LOWER(services.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  scope :by_code, lambda { |value| where("LOWER(services.code) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_price, lambda { |value| where("price >= ?", value) if !value.nil? && !value.blank? }
  scope :by_final_price, lambda { |value| where("price <= ?", value) if !value.nil? && !value.blank? }

  scope :by_category_id, lambda { |value| where("services.category_id = ?", value) if !value.nil? && !value.blank? }

  belongs_to :category, optional: true
  belongs_to :provider, :class_name => 'User', optional: true

  validates_presence_of :name, :category_id

  validates :name, uniqueness: { scope: :category_id, case_sensitive: false }
  validate :check_similar_names

  has_one_attached :image

  # has_attached_file :image,
  # :storage => :s3,
  # :url => ":s3_domain_url",
  # styles: { medium: "300x300#", thumb: "100x100#", select: "50x50#" },
  # :path => ":class/image/:id_partition/:style/:filename"
  # do_not_validate_attachment_file_type :image

  def get_text_name
    self.name.to_s
  end

  def price=(new_price)
    self[:price] = CustomHelper.currency_to_value(new_price)
  end

  def getting_formatted_name_with_price
    result = ''
    result = get_text_name+" ("+CustomHelper.to_currency(self.price)+")"
    return result
  end

  def getting_formatted_name_with_type_and_price
    type_label = case category_id
    when Category::SERVICOS_PECAS_ID
      "[PEÇA]"
    when Category::SERVICOS_SERVICOS_ID
      "[SERVIÇO]"
    else
      ""
    end
    "#{type_label} #{get_text_name} (#{CustomHelper.to_currency(self.price)})"
  end

  def self.getting_values_with_discount(service_id, client_id, quantity)
    discount = 0
    value = 0
    discount_formatted = 'R$ 0,00'
    value_formatted = 'R$ 0,00'
    discount = 0
    value = 0
    discount_formatted = 'R$ 0,00'
    value_formatted = 'R$ 0,00'
    service = Service.where(id: service_id).first
    if service
      quantity = quantity || 1
      client = User.client.where(id: client_id).first
      if client
        discount_percent = client.discount_percent
        service_price = service.price || 0
        total_service_price = service_price.to_f * quantity.to_i
        discount = (total_service_price * (discount_percent.to_f / 100))
        value = (total_service_price - discount)
        discount_formatted = CustomHelper.to_currency(discount)
        value_formatted = CustomHelper.to_currency(value)
      end
    end
    return {
      discount: discount,
      value: value,
      discount_formatted: discount_formatted,
      value_formatted: value_formatted
    }
  end

  def self.getting_values_with_discount_new_product(client_id, price, quantity)
    discount = 0
    value = 0
    discount_formatted = 'R$ 0,00'
    value_formatted = 'R$ 0,00'
    client = User.client.where(id: client_id).first
    if client
      discount_percent = client.discount_percent
      service_price = CustomHelper.currency_to_value(price)
      total_service_price = service_price * quantity.to_i
      discount = (total_service_price * (discount_percent.to_f / 100))
      value = (total_service_price.to_f - discount.to_f)
      discount_formatted = CustomHelper.to_currency(discount)
      value_formatted = CustomHelper.to_currency(value)
    end
    return {
      discount: discount,
      value: value,
      discount_formatted: discount_formatted,
      value_formatted: value_formatted
    }
  end

  private

  def padronizar_nome_service
    self.name = self.class.padronizar_nome_peca(name) if name.present? && name_changed?
  end

  def default_values
    self.name ||= ""
    self.description ||= ""
    self.category_id ||= Category::SERVICOS_PECAS_ID
  end

  def check_similar_names
    return if name.blank?
    
    # Normaliza o nome: lowercase, remove acentos, espaços extras e caracteres especiais
    normalized_name = I18n.transliterate(name.to_s.downcase.strip.gsub(/\s+/, ' '))
    
    # Busca serviços similares na mesma categoria (excluindo o próprio registro se for update)
    similar_services = Service.where(category_id: category_id)
    similar_services = similar_services.where.not(id: id) if persisted?
    
    similar_services.each do |service|
      existing_normalized = I18n.transliterate(service.name.to_s.downcase.strip.gsub(/\s+/, ' '))
      
      # Verifica similaridade exata após normalização
      if normalized_name == existing_normalized
        errors.add(:name, "já existe um item similar: '#{service.name}' (categoria: #{service.category.name})")
        return
      end
      
      # Verifica se um nome está contido no outro (ex: "amortecedor" e "amortecedor dianteiro")
      if normalized_name.length > 3 && existing_normalized.length > 3
        if normalized_name.include?(existing_normalized) || existing_normalized.include?(normalized_name)
          # Apenas alerta se a diferença for muito pequena (menos de 5 caracteres)
          diff = (normalized_name.length - existing_normalized.length).abs
          if diff <= 5
            errors.add(:name, "muito similar a: '#{service.name}' (categoria: #{service.category.name})")
            return
          end
        end
      end
    end
  end

end
