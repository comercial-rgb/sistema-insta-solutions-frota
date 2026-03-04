#!/usr/bin/env python3
"""
Patch: Torna generate_order_service_proposal_items mais robusto
- Usa .create! em vez de .create (falha ruidosa)
- Adiciona logging de cada item criado
- Adiciona verificação pós-geração
- Tudo dentro de transaction para atomicidade
"""

import re

FILE = "app/controllers/order_service_proposals_controller.rb"

# ===== PATCH 1: Rewrite generate_order_service_proposal_items =====

OLD_METHOD = '''  def generate_order_service_proposal_items
    @order_service_proposal.order_service_proposal_items.destroy_all
    # @order_service_proposal.order_service_proposal_items.each do |order_service_proposal_item|
    #   order_service_proposal_item.update_columns(
    #     unity_value: order_service_proposal_item.service.price,
    #     service_name: order_service_proposal_item.service.name,
    #     brand: order_service_proposal_item.service.brand,
    #     warranty_period: order_service_proposal_item.service.warranty_period,
    #     service_description: order_service_proposal_item.service.description,
    #     total_value_without_discount: (order_service_proposal_item.quantity * order_service_proposal_item.service.price)
    #   )
    # end

    @order_service_proposal.provider_service_temps.each do |provider_service_temp|
      new_service = provider_service_temp.service
      
      # Para itens criados manualmente (sem service_id), usa os dados do provider_service_temp
      if new_service.present?
        service_id = new_service.id
        service_name = new_service.name
      else
        service_id = nil
        service_name = provider_service_temp.name
      end
      
      @order_service_proposal.order_service_proposal_items.create(
        service_id: service_id,
        unity_value: provider_service_temp.price,
        service_name: service_name,
        quantity: provider_service_temp.quantity,
        discount: provider_service_temp.discount,
        total_value: provider_service_temp.total_value,
        total_value_without_discount: (provider_service_temp.quantity * provider_service_temp.price),
        brand: provider_service_temp.brand,
        warranty_period: provider_service_temp.warranty_period,
        referencia_catalogo: provider_service_temp.referencia_catalogo
      )
    end
  end'''

NEW_METHOD = '''  def generate_order_service_proposal_items
    proposal_id = @order_service_proposal.id
    temps_count = @order_service_proposal.provider_service_temps.count

    Rails.logger.info "[GENERATE_ITEMS] Proposta #{proposal_id}: Iniciando geração de #{temps_count} itens"

    ActiveRecord::Base.transaction do
      @order_service_proposal.order_service_proposal_items.destroy_all

      @order_service_proposal.provider_service_temps.reload.each do |provider_service_temp|
        new_service = provider_service_temp.service

        # Para itens criados manualmente (sem service_id), usa os dados do provider_service_temp
        if new_service.present?
          service_id = new_service.id
          service_name = new_service.name
        else
          service_id = nil
          service_name = provider_service_temp.name
        end

        item = @order_service_proposal.order_service_proposal_items.create!(
          service_id: service_id,
          unity_value: provider_service_temp.price,
          service_name: service_name,
          quantity: provider_service_temp.quantity,
          discount: provider_service_temp.discount,
          total_value: provider_service_temp.total_value,
          total_value_without_discount: (provider_service_temp.quantity * provider_service_temp.price),
          brand: provider_service_temp.brand,
          warranty_period: provider_service_temp.warranty_period,
          referencia_catalogo: provider_service_temp.referencia_catalogo
        )
        Rails.logger.info "[GENERATE_ITEMS] Proposta #{proposal_id}: Item #{item.id} criado (service_id=#{service_id}, valor=#{provider_service_temp.price}, qty=#{provider_service_temp.quantity})"
      end
    end

    # Verificação pós-geração
    items_count = @order_service_proposal.order_service_proposal_items.reload.count
    if items_count != temps_count
      Rails.logger.error "[GENERATE_ITEMS] ⚠️ MISMATCH Proposta #{proposal_id}: #{temps_count} temps vs #{items_count} items criados!"
    else
      Rails.logger.info "[GENERATE_ITEMS] ✅ Proposta #{proposal_id}: #{items_count} itens gerados com sucesso"
    end
  end'''

print("Patching generate_order_service_proposal_items...")

with open(FILE, "r") as f:
    content = f.read()

# Normalize whitespace for matching (the server file may have different indentation)
def normalize(text):
    lines = text.strip().split('\n')
    return '\n'.join(line.rstrip() for line in lines)

# Try exact match first
if OLD_METHOD.strip() in content:
    content = content.replace(OLD_METHOD.strip(), NEW_METHOD.strip(), 1)
    print("  OK: Método substituído com sucesso (match exato)")
else:
    # Try matching by the unique create( call and surrounding context
    # Find the method boundaries
    start_marker = "def generate_order_service_proposal_items"
    end_marker = "def build_initial_relations"
    
    start_idx = content.find(start_marker)
    end_idx = content.find(end_marker)
    
    if start_idx == -1:
        print("  ERRO: Método generate_order_service_proposal_items não encontrado!")
        exit(1)
    
    if end_idx == -1:
        print("  ERRO: Fim do método (build_initial_relations) não encontrado!")
        exit(1)
    
    # Get indentation
    line_start = content.rfind('\n', 0, start_idx) + 1
    indent = content[line_start:start_idx]
    
    # Replace the method content between start and end markers
    # Find the last line before end_marker that belongs to our method
    method_end = end_idx
    # Go back to find the previous newline
    while method_end > start_idx and content[method_end-1] in (' ', '\t', '\n', '\r'):
        method_end -= 1
    method_end = content.find('\n', method_end) + 1
    
    old_method_text = content[start_idx:method_end]
    
    # Build new method with proper indentation  
    new_method_lines = NEW_METHOD.strip().split('\n')
    indented_new = '\n'.join(new_method_lines) + '\n\n'
    
    content = content[:start_idx] + indented_new + content[end_idx:]
    print("  OK: Método substituído por boundary matching")

with open(FILE, "w") as f:
    f.write(content)

print("\nPatch concluído!")
