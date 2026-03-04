#!/usr/bin/env python3
# Script para injetar SendAuthorizedOsWebhookJob nos controllers restaurados do git

import sys

def patch_file(filepath, old_text, new_text):
    with open(filepath, 'r') as f:
        content = f.read()
    
    if old_text not in content:
        print(f"  AVISO: texto antigo nao encontrado em {filepath}")
        # Try to check if already patched
        if 'SendAuthorizedOsWebhookJob' in content:
            print(f"  -> Ja possui SendAuthorizedOsWebhookJob, pulando")
            return True
        return False
    
    content = content.replace(old_text, new_text, 1)  # Replace only first occurrence
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    print(f"  OK: {filepath} atualizado")
    return True

# 1. Patch order_service_proposals_controller.rb
print("1. Patching order_service_proposals_controller.rb...")
old_proposals = '      # Envia webhook para sistema financeiro (s\u00edncrono)\n      begin\n        WebhookFinanceService.send_authorized_os(@order_service_proposal.order_service.id)\n      rescue => e\n        Rails.logger.error "[OrderServiceProposals] Falha ao enviar webhook: #' + '{e.message}"\n      end'

new_proposals = '      # Envia webhook para sistema financeiro (ass\u00edncrono com retry)\n      SendAuthorizedOsWebhookJob.perform_later(@order_service_proposal.order_service.id)'

patch_file('app/controllers/order_service_proposals_controller.rb', old_proposals, new_proposals)

# 2. Patch order_services_controller.rb
print("2. Patching order_services_controller.rb...")
old_services = '        # Envia webhook para sistema financeiro (s\u00edncrono)\n        begin\n          WebhookFinanceService.send_authorized_os(order_service.id)\n        rescue => e\n          Rails.logger.error "[OrderServices] Falha ao enviar webhook: #' + '{e.message}"\n        end'

new_services = '        # Envia webhook para sistema financeiro (ass\u00edncrono com retry)\n        SendAuthorizedOsWebhookJob.perform_later(order_service.id)'

patch_file('app/controllers/order_services_controller.rb', old_services, new_services)

print("\nConcluido!")
