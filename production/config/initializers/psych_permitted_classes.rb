# frozen_string_literal: true

# Rails 7+ com Psych 4.0+ requer que classes sejam explicitamente permitidas
# para serialização YAML. Isso é necessário para o audited gem funcionar
# corretamente com campos BigDecimal.

Rails.application.config.active_record.yaml_column_permitted_classes = [
  Symbol,
  Date,
  Time,
  DateTime,
  BigDecimal,
  ActiveSupport::TimeWithZone,
  ActiveSupport::TimeZone,
  ActiveSupport::HashWithIndifferentAccess
]
