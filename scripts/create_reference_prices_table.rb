# Cria a tabela reference_prices no banco de dados
sql = <<-SQL
CREATE TABLE reference_prices (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  vehicle_model_id BIGINT NOT NULL,
  service_id BIGINT NOT NULL,
  reference_price DECIMAL(15,2) NOT NULL,
  max_percentage DECIMAL(5,2) DEFAULT 110.0,
  observation TEXT,
  source VARCHAR(255),
  active BOOLEAN DEFAULT TRUE,
  created_at DATETIME(6) NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  
  INDEX index_reference_prices_on_vehicle_model_id (vehicle_model_id),
  INDEX index_reference_prices_on_service_id (service_id),
  INDEX index_reference_prices_on_active (active),
  UNIQUE INDEX index_reference_prices_on_model_and_service (vehicle_model_id, service_id),
  
  CONSTRAINT fk_rails_reference_prices_vehicle_models 
    FOREIGN KEY (vehicle_model_id) REFERENCES vehicle_models(id),
  CONSTRAINT fk_rails_reference_prices_services 
    FOREIGN KEY (service_id) REFERENCES services(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
SQL

begin
  ActiveRecord::Base.connection.execute(sql)
  puts "✅ Tabela reference_prices criada com sucesso!"
  puts "   - Tabela: reference_prices"
  puts "   - Indexes: vehicle_model_id, service_id, active, model+service (unique)"
  puts "   - Foreign keys: vehicle_models, services"
rescue => e
  if e.message.include?("already exists")
    puts "⚠️  Tabela reference_prices já existe"
  else
    puts "❌ Erro ao criar tabela: #{e.message}"
  end
end

# Verificar se foi criada
count = ReferencePrice.count rescue 0
puts "\nTotal de registros na tabela: #{count}"
