# ================================================================
# Script de Verificação - IDs de Status de OS em Produção
# ================================================================
# Este script verifica os IDs corretos dos status no banco de dados
# Execute: rails runner check_production_status.rb

puts "=" * 80
puts "VERIFICAÇÃO DE IDs DE STATUS DE ORDEM DE SERVIÇO"
puts "=" * 80
puts ""

puts "📊 STATUS NO BANCO DE DADOS:"
puts "-" * 80

OrderServiceStatus.order(:id).each do |status|
  puts "ID: #{status.id.to_s.rjust(2)} | Nome: #{status.name}"
end

puts ""
puts "=" * 80
puts "📋 CONSTANTES NO CÓDIGO (app/models/order_service_status.rb):"
puts "-" * 80
puts "EM_ABERTO_ID = #{OrderServiceStatus::EM_ABERTO_ID}"
puts "AGUARDANDO_AVALIACAO_PROPOSTA_ID = #{OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID}"
puts "APROVADA_ID = #{OrderServiceStatus::APROVADA_ID}"
puts "NOTA_FISCAL_INSERIDA_ID = #{OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID}"
puts "AUTORIZADA_ID = #{OrderServiceStatus::AUTORIZADA_ID}"
puts "AGUARDANDO_PAGAMENTO_ID = #{OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID}"
puts "PAGA_ID = #{OrderServiceStatus::PAGA_ID}"
puts "CANCELADA_ID = #{OrderServiceStatus::CANCELADA_ID}"
puts "EM_CADASTRO_ID = #{OrderServiceStatus::EM_CADASTRO_ID}"
puts "EM_REAVALIACAO_ID = #{OrderServiceStatus::EM_REAVALIACAO_ID}"
puts "AGUARDANDO_APROVACAO_COMPLEMENTO_ID = #{OrderServiceStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID}"

puts ""
puts "=" * 80
puts "🔍 VERIFICAÇÃO DE CORRESPONDÊNCIA:"
puts "-" * 80

# Verificar se as constantes batem com os registros do banco
status_aguardando = OrderServiceStatus.find_by(id: OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID)
if status_aguardando
  puts "✅ AGUARDANDO_AVALIACAO_PROPOSTA_ID (#{OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID}): #{status_aguardando.name}"
else
  puts "❌ ERRO: ID #{OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID} não existe no banco!"
  puts "   Procurando status 'Aguardando avaliação' no banco..."
  possible_match = OrderServiceStatus.where("name LIKE ?", "%aguardando%avalia%").first
  if possible_match
    puts "   ⚠️  Encontrado: ID #{possible_match.id} - #{possible_match.name}"
  end
end

puts ""
puts "=" * 80
puts "📝 ORDENS DE SERVIÇO COM STATUS NULL:"
puts "-" * 80

null_status_count = OrderService.where(order_service_status_id: nil).count
puts "Total de OSs com status NULL: #{null_status_count}"

if null_status_count > 0
  puts "\nPrimeiras 5 OSs com status NULL:"
  OrderService.where(order_service_status_id: nil).limit(5).each do |os|
    puts "  - OS ##{os.id} (#{os.code})"
  end
end

puts ""
puts "=" * 80
puts "✅ Verificação concluída!"
puts "=" * 80
