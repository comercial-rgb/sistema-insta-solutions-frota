#!/usr/bin/env ruby
# ================================================================
# Script para MAPEAR e REENVIAR webhooks que falharam ao Portal Financeiro
# Uso: RAILS_ENV=production bundle exec rails runner scripts/map_and_retry_failed_webhooks.rb
# ================================================================

require 'net/http'
require 'json'

puts ""
puts "=" * 70
puts "MAPEAMENTO E RETRY DE WEBHOOKS FALHOS - PORTAL FINANCEIRO"
puts "Data: #{Time.now.strftime('%d/%m/%Y %H:%M')}"
puts "=" * 70
puts ""

# IDs de status Autorizada
autorizada_ids = [OrderServiceStatus::AUTORIZADA_ID]
autorizada_ids << OrderServiceStatus::NEW_AUTORIZADA_ID if defined?(OrderServiceStatus::NEW_AUTORIZADA_ID)
autorizada_ids = autorizada_ids.uniq

# ============================================================
# FASE 1: Mapear TODAS as OS autorizadas de TODOS os clientes
# ============================================================
puts "[FASE 1] Buscando todas as OS autorizadas..."
puts ""

all_authorized = OrderService.unscoped
  .where(order_service_status_id: autorizada_ids)
  .includes(:client, :provider, :order_service_type, :cost_center, :sub_unit, :vehicle,
            order_service_proposals: [:provider, :order_service_proposal_items, :order_service_invoices])

total = all_authorized.count
puts "Total de OS autorizadas no sistema: #{total}"
puts ""

# ============================================================
# FASE 2: Testar envio individual e mapear falhas
# ============================================================
puts "[FASE 2] Testando cada OS no Portal Financeiro..."
puts ""

success_list = []
error_list = []
skip_list = []

all_authorized.find_each.with_index(1) do |os, index|
  client_name = os.client&.fantasy_name || os.client&.social_name || 'Sem cliente'
  print "  [#{index}/#{total}] OS #{os.code} (#{client_name})... "

  begin
    result = WebhookFinanceService.send_authorized_os(os.id)

    if result[:success]
      puts "✅ OK"
      success_list << { code: os.code, client: client_name }
    else
      error_msg = result[:error].to_s
      puts "⚠️  #{error_msg}"
      error_list << { code: os.code, id: os.id, client: client_name, error: error_msg }
    end
  rescue => e
    puts "❌ #{e.message}"
    error_list << { code: os.code, id: os.id, client: client_name, error: "Exceção: #{e.message}" }
  end

  sleep(0.3)
end

# ============================================================
# FASE 3: Relatório detalhado
# ============================================================
puts ""
puts "=" * 70
puts "RELATÓRIO COMPLETO"
puts "=" * 70
puts ""
puts "  ✅ Enviadas com sucesso:  #{success_list.size}"
puts "  ⚠️  Com falha:            #{error_list.size}"
puts "  📋 Total processadas:     #{total}"
puts ""

if error_list.any?
  # Agrupar por tipo de erro
  by_reason = error_list.group_by do |e|
    case e[:error]
    when /Fornecedor.*não encontrado/
      fornecedor = e[:error].match(/"([^"]+)"/)[1] rescue 'Desconhecido'
      "Fornecedor não cadastrado no Portal: #{fornecedor}"
    when /Cliente.*não encontrado/
      cliente = e[:error].match(/"([^"]+)"/)[1] rescue 'Desconhecido'
      "Cliente não cadastrado no Portal: #{cliente}"
    when /sem proposta aprovada/
      "OS sem proposta aprovada"
    when /sem fornecedor/i
      "Proposta sem fornecedor"
    when /sem nome cadastrado/i
      "Fornecedor sem nome cadastrado"
    else
      e[:error].truncate(80)
    end
  end

  puts "-" * 70
  puts "DETALHAMENTO POR MOTIVO DE FALHA:"
  puts "-" * 70
  puts ""

  by_reason.sort_by { |_reason, items| -items.size }.each do |reason, items|
    puts "  🔴 #{reason} (#{items.size} OS):"
    items.each do |item|
      puts "     - #{item[:code]} | Cliente: #{item[:client]}"
    end
    puts ""
  end

  puts "-" * 70
  puts "AÇÃO NECESSÁRIA:"
  puts "-" * 70
  puts ""

  fornecedores_missing = by_reason.select { |r, _| r.start_with?("Fornecedor não cadastrado") }
  clientes_missing = by_reason.select { |r, _| r.start_with?("Cliente não cadastrado") }

  if fornecedores_missing.any?
    puts "  📌 Fornecedores para CADASTRAR no Portal Financeiro:"
    fornecedores_missing.each do |reason, items|
      nome = reason.sub("Fornecedor não cadastrado no Portal: ", "")
      puts "     → #{nome} (#{items.size} OS afetadas)"
    end
    puts ""
  end

  if clientes_missing.any?
    puts "  📌 Clientes para CADASTRAR no Portal Financeiro:"
    clientes_missing.each do |reason, items|
      nome = reason.sub("Cliente não cadastrado no Portal: ", "")
      puts "     → #{nome} (#{items.size} OS afetadas)"
    end
    puts ""
  end

  puts "  Após cadastrar no Portal, rode este script novamente para reenviar."
end

puts ""
puts "=" * 70
puts "Concluído em #{Time.now.strftime('%d/%m/%Y %H:%M')}"
puts "=" * 70
