<%- module_namespacing do -%>
class <%= class_name %> < <%= parent_class_name.classify %>
  after_initialize :default_values

  default_scope {
    order(:id)
  }

  scope :by_id, lambda { |value| where("<%= plural_table_name %>.id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(<%= plural_table_name %>.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  
  scope :by_initial_date, lambda { |value| where("<%= plural_table_name %>.created_at >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("<%= plural_table_name %>.created_at <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  <%- attributes.select(&:reference?).each do |attribute| -%>
  belongs_to :<%= attribute.name %><%= ', polymorphic: true' if attribute.polymorphic? %><%= ', required: true' if attribute.required? %>
  <%- end -%>
  <%- attributes.select(&:token?).each do |attribute| -%>
    has_secure_token<%- if attribute.name != "token" -%> :<%= attribute.name %><%- end -%>
  <%- end -%>
  <%- if attributes.any?(&:password_digest?) -%>
  has_secure_password
  <%- end -%>
  
  def get_text_name
    self.id.to_s
  end

  private

  def default_values
  end

end
<%- end -%>
