# =============================================================================
# SCRIPT DE PREPARAÇÃO PARA PROVA DE CONCEITO — Frota Insta Solutions
# Cobre todos os itens dos Blocos 01–06 (TR 5.37 a TR 5.60)
#
# Execução:
#   rails runner poc_seed.rb
#
# ATENÇÃO: Execute apenas em ambiente de HOMOLOGAÇÃO / DEMO.
#          Remove registros poc_* anteriores antes de recriar (idempotente).
# =============================================================================

puts "=" * 70
puts "INÍCIO DO SEED DE PoC — #{Time.current.strftime('%d/%m/%Y %H:%M:%S')}"
puts "=" * 70

# ---------------------------------------------------------------------------
# 0. DADOS BASE (tabelas de lookup — devem existir)
# ---------------------------------------------------------------------------

user_status_ativo = UserStatus.find_by(id: UserStatus::APROVADO_ID)
abort "[ERRO] UserStatus##{UserStatus::APROVADO_ID} não encontrado." unless user_status_ativo

fuel_type = FuelType.first
abort "[ERRO] FuelType não encontrado — rode as seeds principais." unless fuel_type

provider_service_type = ProviderServiceType.first
abort "[ERRO] ProviderServiceType não encontrado — rode as seeds principais." unless provider_service_type

budget_type = BudgetType.find_by(id: BudgetType::ANUAL_ID) || BudgetType.first
abort "[ERRO] BudgetType não encontrado." unless budget_type

# IDs reais do DB (podem divergir dos constants quando seeds rodaram em ordem diferente)
OS_TYPE_COTACOES    = OrderServiceType.where("LOWER(name) LIKE ?", '%cota%').first&.id  || OrderServiceType.first.id
OS_TYPE_EMERGENCIAL = OrderServiceType.where("LOWER(name) LIKE ?", '%emerg%').first&.id || OrderServiceType.first.id
OS_TYPE_REQUISICAO  = OrderServiceType.where("LOWER(name) LIKE ?", '%requi%').first&.id || OrderServiceType.first.id

OS_STATUS_EM_ABERTO           = OrderServiceStatus.where("LOWER(name) LIKE ?", '%em aberto%').first&.id
OS_STATUS_AGUARDANDO_AVALIACAO = OrderServiceStatus.where("LOWER(name) LIKE ?", '%aguardando avalia%').first&.id
OS_STATUS_APROVADA            = OrderServiceStatus.where("LOWER(name) LIKE ?", '%aprovada%').first&.id
OS_STATUS_PAGA                = OrderServiceStatus.where("LOWER(name) = ?", 'paga').first&.id
OS_STATUS_CANCELADA           = OrderServiceStatus.where("LOWER(name) = ?", 'cancelada').first&.id

PROP_STATUS_EM_CADASTRO    = OrderServiceProposalStatus.where("LOWER(name) LIKE ?", '%em cadastro%').first&.id
PROP_STATUS_AG_AVALIACAO   = OrderServiceProposalStatus.where("LOWER(name) LIKE ?", '%aguardando avalia%').first&.id
PROP_STATUS_APROVADA       = OrderServiceProposalStatus.where("LOWER(name) = ?", 'aprovada').first&.id
PROP_STATUS_PAGA           = OrderServiceProposalStatus.where("LOWER(name) = ?", 'paga').first&.id

CAT_PECAS    = Category.where("LOWER(name) LIKE ?", '%pe%').first&.id || 1
CAT_SERVICOS = Category.where("LOWER(name) LIKE ?", '%servi%').first&.id || 2

MAINT_PLAN_ID = MaintenancePlan.where(client_id: nil).where("LOWER(name) LIKE ?", '%prevent%').first&.id ||
                MaintenancePlan.where(client_id: nil).first&.id

[OS_TYPE_COTACOES, OS_STATUS_EM_ABERTO, OS_STATUS_APROVADA, PROP_STATUS_AG_AVALIACAO].each_with_index do |val, i|
  abort "[ERRO] Lookup #{i} retornou nil — verifique os dados base no DB." unless val
end

puts "[PoC] Dados base OK"
puts "[PoC]   OS Types — Cotações:#{OS_TYPE_COTACOES}, Emergencial:#{OS_TYPE_EMERGENCIAL}, Requisição:#{OS_TYPE_REQUISICAO}"
puts "[PoC]   OS Status — EmAberto:#{OS_STATUS_EM_ABERTO}, Aprovada:#{OS_STATUS_APROVADA}, Paga:#{OS_STATUS_PAGA}, Cancelada:#{OS_STATUS_CANCELADA}"
puts "[PoC]   Proposal — EmCadastro:#{PROP_STATUS_EM_CADASTRO}, AgAvaliacao:#{PROP_STATUS_AG_AVALIACAO}, Aprovada:#{PROP_STATUS_APROVADA}, Paga:#{PROP_STATUS_PAGA}"
puts "[PoC]   Categorias — Peças:#{CAT_PECAS}, Serviços:#{CAT_SERVICOS} | MaintenancePlan:#{MAINT_PLAN_ID}"

# ---------------------------------------------------------------------------
# 1. LIMPAR registros fictícios anteriores (idempotência)
# ---------------------------------------------------------------------------

POC_EMAILS = %w[
  poc.admin@frotademo.gov.br
  poc.contratante@frotademo.gov.br
  poc.gestor@frotademo.gov.br
  poc.adicional@frotademo.gov.br
  poc.fornecedor1@autopecastotal.com.br
  poc.fornecedor2@mecanicaprecisa.com.br
].freeze

puts "[PoC] Removendo registros anteriores..."

poc_user_ids = User.where(email: POC_EMAILS).pluck(:id)

if poc_user_ids.any?
  # Coletar IDs dependentes antes de deletar
  poc_vehicle_ids    = Vehicle.where(client_id: poc_user_ids).pluck(:id)
  poc_os_ids         = OrderService.where(client_id: poc_user_ids).pluck(:id)
  poc_proposal_ids   = OrderServiceProposal.where(order_service_id: poc_os_ids).pluck(:id)
  poc_cc_ids         = CostCenter.where(client_id: poc_user_ids).pluck(:id)
  poc_commit_ids     = Commitment.where(client_id: poc_user_ids).pluck(:id)
  poc_mplan_ids      = MaintenancePlan.where(client_id: poc_user_ids).pluck(:id) # apenas os criados pelo seed PoC
  poc_checklist_ids  = VehicleChecklist.where(client_id: poc_user_ids).pluck(:id)

  # Deletar na ordem correta (filhos primeiro)
  Audited::Audit.where(auditable_type: 'OrderServiceProposal', auditable_id: poc_proposal_ids).delete_all if poc_proposal_ids.any?
  Audited::Audit.where(auditable_type: 'OrderService',         auditable_id: poc_os_ids).delete_all        if poc_os_ids.any?
  Audited::Audit.where(user_id: poc_user_ids).delete_all

  ProviderServiceTemp.where(order_service_proposal_id: poc_proposal_ids).delete_all if poc_proposal_ids.any?
  OrderServiceProposalItem.where(order_service_proposal_id: poc_proposal_ids).delete_all if poc_proposal_ids.any?
  OrderServiceProposal.where(id: poc_proposal_ids).delete_all if poc_proposal_ids.any?

  WebhookLog.where(order_service_id: poc_os_ids).delete_all if poc_os_ids.any?
  ActiveRecord::Base.connection.execute("DELETE FROM order_service_directed_providers WHERE order_service_id IN (#{poc_os_ids.join(',')})") if poc_os_ids.any?
  OrderService.where(id: poc_os_ids).delete_all             if poc_os_ids.any?

  VehicleChecklistItem.where(vehicle_checklist_id: poc_checklist_ids).delete_all if poc_checklist_ids.any?
  VehicleChecklist.where(id: poc_checklist_ids).delete_all                        if poc_checklist_ids.any?

  VehicleKmRecord.where(vehicle_id: poc_vehicle_ids).delete_all if poc_vehicle_ids.any?
  # Deletar maintenance_alerts antes dos veículos (FK constraint)
  MaintenanceAlert.where(vehicle_id: poc_vehicle_ids).delete_all if poc_vehicle_ids.any? && defined?(MaintenanceAlert)
  ActiveRecord::Base.connection.execute("DELETE FROM maintenance_alerts WHERE vehicle_id IN (#{poc_vehicle_ids.join(',')})") if poc_vehicle_ids.any?
  Vehicle.where(id: poc_vehicle_ids).delete_all                  if poc_vehicle_ids.any?

  Commitment.where(id: poc_commit_ids).delete_all      if poc_commit_ids.any?
  MaintenancePlan.where(id: poc_mplan_ids).delete_all  if poc_mplan_ids.any?
  poc_contract_ids = Contract.where(client_id: poc_user_ids).pluck(:id)
  if poc_contract_ids.any?
    ActiveRecord::Base.connection.execute("DELETE FROM contracts_cost_centers WHERE contract_id IN (#{poc_contract_ids.join(',')})")
    Contract.where(id: poc_contract_ids).delete_all
  end
  ActiveRecord::Base.connection.execute("DELETE FROM cost_centers_users WHERE cost_center_id IN (#{poc_cc_ids.join(',')})") if poc_cc_ids.any?
  CostCenter.where(id: poc_cc_ids).delete_all          if poc_cc_ids.any?

  ApiKey.where(user_id: poc_user_ids).delete_all

  # Limpar notificações PoC e marcações de leitura/reconhecimento
  poc_notif_ids = Notification.where("title LIKE ?", '%[PoC]%').pluck(:id)
  if poc_notif_ids.any?
    NotificationAcknowledgment.where(notification_id: poc_notif_ids).delete_all
    ActiveRecord::Base.connection.execute("DELETE FROM notifications_users WHERE notification_id IN (#{poc_notif_ids.join(',')})")
    ActiveRecord::Base.connection.execute("DELETE FROM read_marks WHERE readable_type = 'Notification' AND readable_id IN (#{poc_notif_ids.join(',')})")
    Notification.where(id: poc_notif_ids).delete_all
  end
  # Limpar read_marks globais de notificações para usuários PoC (mark_all_as_read)
  ActiveRecord::Base.connection.execute(
    "DELETE FROM read_marks WHERE reader_type = 'User' AND reader_id IN (#{poc_user_ids.join(',')}) AND readable_type = 'Notification'"
  ) if poc_user_ids.any?

  # Desativa FK temporariamente para deletar users com auto-referência (client_id)
  ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 0")
  User.where(id: poc_user_ids).delete_all
  ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 1")

  puts "[PoC]   #{poc_user_ids.size} usuário(s) e todos os registros dependentes removidos"
else
  puts "[PoC]   Nenhum registro anterior encontrado"
end

# ---------------------------------------------------------------------------
# 2. HELPER: criar usuário contornando validações não-aplicáveis a seeds
# ---------------------------------------------------------------------------
# Usamos save(validate: false) pois:
#   - current_plan_id: coluna removida do schema, validação é código legado
#   - Todos os campos críticos (profile, email, password) são preenchidos
#   - Dados são fictícios e controlados

def create_poc_user(attrs)
  plain_pw = attrs.delete(:plain_password)
  user = User.new(attrs.merge(
    validated_mail: true,
    accept_therm:   true,
    seed:           true
  ))
  user.password              = plain_pw
  user.password_confirmation = plain_pw
  unless user.save(validate: false)
    abort "[ERRO] Falha ao salvar #{attrs[:email]}: #{user.errors.full_messages.join(', ')}"
  end
  user
end

# ---------------------------------------------------------------------------
# 3. USUÁRIOS (6 perfis para a demonstração)
# ---------------------------------------------------------------------------
# Profile IDs: ADMIN=1, USER=2, MANAGER=4, ADDITIONAL=5, PROVIDER=6

puts "[PoC] Criando usuários..."

admin = create_poc_user(
  profile_id:     Profile::ADMIN_ID,
  name:           'Administrador PoC',
  email:          'poc.admin@frotademo.gov.br',
  plain_password: 'PoC@2025!',
  user_status_id: user_status_ativo.id,
  phone:          '51900000001',
  cpf:            '111.222.333-00'
)
puts "[PoC]   Admin: #{admin.email} (id=#{admin.id})"

contratante = create_poc_user(
  profile_id:        Profile::USER_ID,
  name:              'Universidade Federal Demo — UFRGS PoC',
  email:             'poc.contratante@frotademo.gov.br',
  plain_password:    'PoC@2025!',
  user_status_id:    user_status_ativo.id,
  social_name:       'UFRGS – Pró-Reitoria de Infraestrutura',
  fantasy_name:      'UFRGS Demo',
  cnpj:              '92.969.999/0001-77',
  phone:             '51900000002',
  government_sphere: 1,
  needs_km:          true
)
contratante.update_column(:qr_nfc_enabled, true)
puts "[PoC]   Contratante: #{contratante.email} (id=#{contratante.id}) — qr_nfc_enabled: true"

gestor = create_poc_user(
  profile_id:     Profile::MANAGER_ID,
  name:           'João Silva — Gestor de Frota PoC',
  email:          'poc.gestor@frotademo.gov.br',
  plain_password: 'PoC@2025!',
  user_status_id: user_status_ativo.id,
  client_id:      contratante.id,
  phone:          '51900000003',
  registration:   'SIAPE-12345',
  cpf:            '123.456.789-00'
)
puts "[PoC]   Gestor: #{gestor.email} (id=#{gestor.id})"

adicional = create_poc_user(
  profile_id:     Profile::ADDITIONAL_ID,
  name:           'Maria Oliveira — Adicional PoC',
  email:          'poc.adicional@frotademo.gov.br',
  plain_password: 'PoC@2025!',
  user_status_id: user_status_ativo.id,
  client_id:      contratante.id,
  phone:          '51900000004',
  registration:   'SIAPE-67890',
  cpf:            '987.654.321-00'
)
puts "[PoC]   Adicional: #{adicional.email} (id=#{adicional.id})"

fornecedor1 = create_poc_user(
  profile_id:     Profile::PROVIDER_ID,
  name:           'Auto Peças Total Ltda',
  email:          'poc.fornecedor1@autopecastotal.com.br',
  plain_password: 'PoC@2025!',
  user_status_id: user_status_ativo.id,
  fantasy_name:   'Auto Peças Total',
  social_name:    'Auto Peças Total Ltda',
  cnpj:           '11.222.333/0001-44',
  phone:          '51900000005'
)
fornecedor1.provider_service_types << provider_service_type rescue nil
puts "[PoC]   Fornecedor 1: #{fornecedor1.email} (id=#{fornecedor1.id})"

fornecedor2 = create_poc_user(
  profile_id:      Profile::PROVIDER_ID,
  name:            'Mecânica Precisa Serviços ME',
  email:           'poc.fornecedor2@mecanicaprecisa.com.br',
  plain_password:  'PoC@2025!',
  user_status_id:  user_status_ativo.id,
  fantasy_name:    'Mecânica Precisa',
  social_name:     'Mecânica Precisa Serviços ME',
  cnpj:            '55.666.777/0001-88',
  phone:           '51900000006',
  optante_simples: true
)
fornecedor2.provider_service_types << provider_service_type rescue nil
puts "[PoC]   Fornecedor 2: #{fornecedor2.email} (id=#{fornecedor2.id})"

# ---------------------------------------------------------------------------
# 4. API KEYS (para demo da API V2 — Blocos 03 e 04)
# ---------------------------------------------------------------------------

puts "[PoC] Criando API Keys..."
api_keys = {}
[admin, contratante, gestor, fornecedor1, fornecedor2].each do |u|
  key = ApiKey.create!(user_id: u.id, expires_at: 1.year.from_now)
  api_keys[u.email] = key.access_token
  puts "[PoC]   #{u.email}: #{key.access_token}"
end

# ---------------------------------------------------------------------------
# 5. CENTRO DE CUSTO, EMPENHO E PLANO DE MANUTENÇÃO
# ---------------------------------------------------------------------------

puts "[PoC] Criando Centro de Custo..."
cost_center = CostCenter.new(
  client_id:          contratante.id,
  name:               'Pró-Reitoria de Infraestrutura — PoC',
  contract_number:    'CONTRATO-2025/001-DEMO',
  budget_type_id:     budget_type.id,
  budget_value:       500_000.00,
  description:        'Centro de custo para Prova de Conceito do sistema Frota Insta Solutions',
  invoice_name:       'Universidade Federal Demo',
  invoice_cnpj:       '92.969.999/0001-77'
)
cost_center.skip_validations = true  # contorna validações de campos opcionais
unless cost_center.save
  cost_center.save(validate: false)
end
puts "[PoC]   CostCenter##{cost_center.id}: #{cost_center.name}"

# Empenho geral (commitment_id) vinculado ao centro de custo
commitment = Commitment.new(
  client_id:         contratante.id,
  cost_center_id:    cost_center.id,
  commitment_number: 'EMPENHO-2025/001-DEMO',
  commitment_value:  300_000.00,
  active:            true
)
commitment.save(validate: false)
abort "[ERRO] Commitment não salvo" if commitment.new_record?
puts "[PoC]   Commitment##{commitment.id}: R$ 300.000,00"

# Contrato (necessário para o gráfico "Saldo do contrato" no dashboard)
contract = Contract.create!(
  client_id:    contratante.id,
  name:         'Contrato 001/2025 — Manutenção da Frota UFRGS Demo',
  number:       '001/2025-DEMO',
  total_value:  500_000.00,
  initial_date: '01/01/2025',
  final_date:   '31/12/2026',
  active:       true
)
ActiveRecord::Base.connection.execute(
  "INSERT INTO contracts_cost_centers (contract_id, cost_center_id) VALUES (#{contract.id}, #{cost_center.id})"
)
puts "[PoC]   Contract##{contract.id}: R$ 500.000,00 — vinculado ao CC"

# Vincular gestor e adicional ao centro de custo (necessário para dashboard mostrar dados)
gestor.associated_cost_centers << cost_center rescue nil
adicional.associated_cost_centers << cost_center rescue nil
puts "[PoC]   Gestor e Adicional vinculados ao CostCenter##{cost_center.id}"

# Plano de manutenção — usa o do sistema se já existir, cria poc se não
maintenance_plan_id_to_use = MAINT_PLAN_ID || begin
  mp = MaintenancePlan.create!(name: 'Preventiva PoC', active: true)
  mp.id
end
puts "[PoC]   MaintenancePlan##{maintenance_plan_id_to_use} (sistema)"

# ---------------------------------------------------------------------------
# 6. VEÍCULOS (3 veículos da frota UFRGS Demo)
# ---------------------------------------------------------------------------

puts "[PoC] Criando veículos..."

v1 = Vehicle.create!(
  client_id:        contratante.id,
  cost_center_id:   cost_center.id,
  fuel_type_id:     fuel_type.id,
  board:            'POC-0001',
  brand:            'Volkswagen',
  model:            'Gol',
  year:             '2019',
  model_year:       '2020',
  color:            'Branco',
  renavam:          '00100200301',
  chassi:           '9BWZZZ377VT004251',
  active:           true,
  market_value:     42_000.00,
  acquisition_date: Date.new(2019, 3, 15)
)
puts "[PoC]   #{v1.board} — #{v1.brand} #{v1.model} (id=#{v1.id})"

v2 = Vehicle.create!(
  client_id:        contratante.id,
  cost_center_id:   cost_center.id,
  fuel_type_id:     fuel_type.id,
  board:            'POC-0002',
  brand:            'Fiat',
  model:            'Strada',
  year:             '2021',
  model_year:       '2021',
  color:            'Prata',
  renavam:          '00200300402',
  chassi:           '9BD158AEB5B503241',
  active:           true,
  market_value:     78_000.00,
  acquisition_date: Date.new(2021, 6, 10)
)
puts "[PoC]   #{v2.board} — #{v2.brand} #{v2.model} (id=#{v2.id})"

v3 = Vehicle.create!(
  client_id:        contratante.id,
  cost_center_id:   cost_center.id,
  fuel_type_id:     fuel_type.id,
  board:            'POC-0003',
  brand:            'Toyota',
  model:            'Hilux',
  year:             '2022',
  model_year:       '2023',
  color:            'Cinza',
  renavam:          '00300400503',
  chassi:           'MR0EX32G400000123',
  active:           true,
  market_value:     185_000.00,
  acquisition_date: Date.new(2022, 11, 5)
)
puts "[PoC]   #{v3.board} — #{v3.brand} #{v3.model} (id=#{v3.id})"

# ---------------------------------------------------------------------------
# 7. REGISTROS DE KM (VehicleKmRecord — tabela vehicle_km_records)
# ---------------------------------------------------------------------------

puts "[PoC] Criando registros de KM..."

VehicleKmRecord.create!(vehicle_id: v1.id, user_id: gestor.id, km: 45_200, origin: 'manual', observation: 'KM inicial PoC')
VehicleKmRecord.create!(vehicle_id: v1.id, user_id: gestor.id, km: 46_800, origin: 'manual', observation: 'Após revisão mensal')
VehicleKmRecord.create!(vehicle_id: v2.id, user_id: gestor.id, km: 12_500, origin: 'manual', observation: 'KM inicial PoC')
VehicleKmRecord.create!(vehicle_id: v3.id, user_id: gestor.id, km: 8_300,  origin: 'manual', observation: 'KM inicial PoC')
puts "[PoC]   4 registros de KM criados"

# ---------------------------------------------------------------------------
# 8. CHECKLISTS (com e sem anomalias — Bloco 04)
# ---------------------------------------------------------------------------

puts "[PoC] Criando checklists..."

cl1 = VehicleChecklist.create!(
  vehicle_id:         v1.id,
  user_id:            gestor.id,
  client_id:          contratante.id,
  cost_center_id:     cost_center.id,
  current_km:         46_800,
  status:             'acknowledged',
  general_notes:      'Inspeção de rotina mensal. Anomalia crítica identificada nos freios.',
  acknowledged_at:    2.days.ago,
  acknowledged_by_id: gestor.id
)
VehicleChecklistItem.create!([
  { vehicle_checklist_id: cl1.id, category: 'motor',   item_name: 'Nível de óleo',         condition: 'ok',       has_anomaly: false, observation: 'Nível adequado' },
  { vehicle_checklist_id: cl1.id, category: 'freios',  item_name: 'Pastilha dianteira',     condition: 'critical', has_anomaly: true,  observation: 'Pastilha desgastada — substituição urgente' },
  { vehicle_checklist_id: cl1.id, category: 'pneus',   item_name: 'Pneu traseiro esquerdo', condition: 'attention',has_anomaly: false, observation: 'Desgaste irregular — monitorar' },
  { vehicle_checklist_id: cl1.id, category: 'fluidos', item_name: 'Fluido de freio',         condition: 'ok',       has_anomaly: false, observation: 'Nível OK' },
  { vehicle_checklist_id: cl1.id, category: 'luzes',   item_name: 'Farol dianteiro D',       condition: 'ok',       has_anomaly: false, observation: 'Funcionando' },
])
puts "[PoC]   Checklist ##{cl1.id} — #{v1.board} com anomalia crítica (acknowledged)"

cl2 = VehicleChecklist.create!(
  vehicle_id:     v2.id,
  user_id:        gestor.id,
  client_id:      contratante.id,
  cost_center_id: cost_center.id,
  current_km:     12_500,
  status:         'closed',
  general_notes:  'Veículo em perfeito estado. Nenhuma anomalia identificada.'
)
VehicleChecklistItem.create!([
  { vehicle_checklist_id: cl2.id, category: 'motor',   item_name: 'Nível de óleo',    condition: 'ok', has_anomaly: false },
  { vehicle_checklist_id: cl2.id, category: 'pneus',   item_name: 'Calibragem geral', condition: 'ok', has_anomaly: false },
  { vehicle_checklist_id: cl2.id, category: 'fluidos', item_name: 'Água do radiador', condition: 'ok', has_anomaly: false },
])
puts "[PoC]   Checklist ##{cl2.id} — #{v2.board} sem anomalias (closed)"

# ---------------------------------------------------------------------------
# 9. ORDENS DE SERVIÇO (5 OS em estados distintos)
# ---------------------------------------------------------------------------

puts "[PoC] Criando Ordens de Serviço..."

def create_os(attrs)
  os = OrderService.new(attrs)
  os.save(validate: false)
  abort "[ERRO] Falha ao salvar OS: #{os.errors.full_messages.join(', ')}" if os.new_record?
  os.send(:generate_code) if os.code.blank?
  os
end

os_base = {
  client_id:                contratante.id,
  manager_id:               gestor.id,
  provider_service_type_id: provider_service_type.id,
  maintenance_plan_id:      maintenance_plan_id_to_use,
  commitment_id:            commitment.id,
  order_service_type_id:    OS_TYPE_COTACOES,
}

os1 = create_os(os_base.merge(
  vehicle_id:                     v1.id,
  order_service_status_id:        OS_STATUS_EM_ABERTO,
  km:                             46_800,
  details:                        'Substituição de pastilhas de freio dianteiras — anomalia identificada em checklist.',
  directed_to_specific_providers: true
))
os1.directed_providers << fornecedor1 rescue nil
puts "[PoC]   #{os1.code} — EM ABERTO (#{v1.board}) — direcionada ao Fornecedor 1"

os2 = create_os(os_base.merge(
  vehicle_id:              v1.id,
  order_service_status_id: OS_STATUS_AGUARDANDO_AVALIACAO,
  km:                      45_200,
  details:                 'Revisão preventiva 45.000 km — troca de óleo, filtros e revisão geral.'
))
puts "[PoC]   #{os2.code} — AGUARDANDO AVALIAÇÃO (#{v1.board}) — receberá 2 propostas"

os3 = create_os(os_base.merge(
  vehicle_id:              v2.id,
  order_service_status_id: OS_STATUS_APROVADA,
  km:                      12_500,
  details:                 'Reparo no sistema elétrico — farol com defeito intermitente.'
))
puts "[PoC]   #{os3.code} — APROVADA (#{v2.board})"

os4 = create_os(os_base.merge(
  vehicle_id:              v3.id,
  order_service_status_id: OS_STATUS_PAGA,
  km:                      8_300,
  details:                 'Alinhamento e balanceamento completo + troca de amortecedor traseiro E.',
  invoiced:                true,
  invoiced_at:             1.month.ago
))
puts "[PoC]   #{os4.code} — PAGA (#{v3.board}) — ciclo completo"

os5 = create_os(os_base.merge(
  vehicle_id:              v2.id,
  order_service_status_id: OS_STATUS_CANCELADA,
  order_service_type_id:   OS_TYPE_EMERGENCIAL,
  km:                      12_000,
  details:                 'Diagnóstico de ruído no câmbio.',
  cancel_justification:    'Cancelada pelo gestor — veículo encaminhado para concessionária autorizada.'
))
puts "[PoC]   #{os5.code} — CANCELADA (#{v2.board})"

# OS Histórica — PAGA (POC-0001, Fornecedor 1) — usada pelo "Reaproveitar Orçamento Anterior"
os_hist = create_os(os_base.merge(
  vehicle_id:              v1.id,
  order_service_status_id: OS_STATUS_PAGA,
  km:                      44_100,
  details:                 'Troca de pastilhas de freio dianteiras e traseiras — manutenção preventiva.',
  invoiced:                true,
  invoiced_at:             3.months.ago
))
puts "[PoC]   #{os_hist.code} — HISTÓRICA PAGA (#{v1.board}) — referência para Reaproveitar Orçamento"

# ---------------------------------------------------------------------------
# 10. PROPOSTAS E ITENS
# ---------------------------------------------------------------------------
# Propostas submetidas (ag. avaliação, aprovada, paga) → OrderServiceProposalItem (visível em "Ver Proposta")
# ProviderServiceTemp também criado para que o formulário de edição funcione
# ---------------------------------------------------------------------------

puts "[PoC] Criando propostas..."

def create_proposal_items(proposal_id, items)
  items.each do |item|
    OrderServiceProposalItem.create!(
      order_service_proposal_id:    proposal_id,
      service_id:                   item[:service_id],
      service_name:                 item[:name],
      service_description:          item[:description],
      quantity:                     item[:quantity],
      unity_value:                  item[:price],
      discount:                     item[:discount],
      total_value:                  item[:total_value],
      total_value_without_discount: (item[:price].to_f * item[:quantity].to_i),
      brand:                        item[:brand],
      warranty_period:              item[:warranty_period]
    )
    ProviderServiceTemp.create!(
      order_service_proposal_id: proposal_id,
      name:                      item[:name],
      code:                      item[:code],
      price:                     item[:price],
      quantity:                  item[:quantity],
      discount:                  item[:discount],
      total_value:               item[:total_value],
      category_id:               item[:category_id],
      brand:                     item[:brand],
      warranty_period:           item[:warranty_period]
    )
  end
end

# OS2 — 2 cotações concorrentes (demonstração de avaliação comparativa)
prop1 = OrderServiceProposal.create!(
  order_service_id:                 os2.id,
  provider_id:                      fornecedor1.id,
  order_service_proposal_status_id: PROP_STATUS_AG_AVALIACAO,
  total_value:                      394.90,
  total_value_without_discount:     394.90,
  details:                          'Revisão preventiva com peças originais. Garantia de 6 meses nas peças.'
)
prop1_items = [
  { name: 'Filtro de Óleo Original VW',     code: 'FO-VW-001',   price: 89.90,  quantity: 1, discount: 0, total_value: 89.90,  category_id: CAT_PECAS,    brand: 'Volkswagen', warranty_period: 180 },
  { name: 'Óleo Motor 5W30 Sintético (4L)', code: 'OM-5W30-4L',  price: 185.00, quantity: 1, discount: 0, total_value: 185.00, category_id: CAT_PECAS,    brand: 'Castrol',    warranty_period: 90 },
  { name: 'Mão de obra — Troca de óleo',    code: 'MO-OLEO-001', price: 120.00, quantity: 1, discount: 0, total_value: 120.00, category_id: CAT_SERVICOS, warranty_period: 30 },
]
create_proposal_items(prop1.id, prop1_items)
puts "[PoC]   Proposta ##{prop1.id} — Fornecedor 1 para #{os2.code} (R$ 394,90)"

prop2 = OrderServiceProposal.create!(
  order_service_id:                 os2.id,
  provider_id:                      fornecedor2.id,
  order_service_proposal_status_id: PROP_STATUS_AG_AVALIACAO,
  total_value:                      300.25,
  total_value_without_discount:     305.00,
  details:                          'Peças certificadas com garantia de 90 dias. Menor prazo de entrega.'
)
prop2_items = [
  { name: 'Filtro de Óleo Universal',              code: 'FO-UNI-015', price: 65.00,  quantity: 1, discount: 0, total_value: 65.00,  category_id: CAT_PECAS,    brand: 'Mann Filter', warranty_period: 90 },
  { name: 'Óleo Motor 5W30 Semi-Sintético (4L)',   code: 'OM-SS-4L',   price: 145.00, quantity: 1, discount: 0, total_value: 145.00, category_id: CAT_PECAS,    brand: 'Mobil',       warranty_period: 90 },
  { name: 'Mão de obra — Revisão completa',        code: 'MO-REV-001', price: 95.00,  quantity: 1, discount: 5, total_value: 90.25,  category_id: CAT_SERVICOS, warranty_period: 30 },
]
create_proposal_items(prop2.id, prop2_items)
puts "[PoC]   Proposta ##{prop2.id} — Fornecedor 2 para #{os2.code} (R$ 300,25)"

# OS3 — Proposta aprovada
prop3 = OrderServiceProposal.create!(
  order_service_id:                 os3.id,
  provider_id:                      fornecedor1.id,
  order_service_proposal_status_id: PROP_STATUS_APROVADA,
  total_value:                      298.00,
  total_value_without_discount:     298.00,
  details:                          'Reparo elétrico com diagnóstico completo. Garantia de 90 dias.'
)
prop3_items = [
  { name: 'Lâmpada Farol H7 par',                        code: 'LF-H7-PAR',   price: 78.00,  quantity: 1, discount: 0, total_value: 78.00,  category_id: CAT_PECAS,    brand: 'Osram', warranty_period: 180 },
  { name: 'Mão de obra — Diagnóstico e reparo elétrico',  code: 'MO-ELET-001', price: 220.00, quantity: 1, discount: 0, total_value: 220.00, category_id: CAT_SERVICOS, warranty_period: 30 },
]
create_proposal_items(prop3.id, prop3_items)
puts "[PoC]   Proposta ##{prop3.id} — Fornecedor 1 para #{os3.code} (APROVADA, R$ 298,00)"

# OS4 — Proposta paga (ciclo completo)
prop4 = OrderServiceProposal.create!(
  order_service_id:                 os4.id,
  provider_id:                      fornecedor2.id,
  order_service_proposal_status_id: PROP_STATUS_PAGA,
  total_value:                      710.00,
  total_value_without_discount:     730.00,
  details:                          'Alinhamento, balanceamento e amortecedor concluídos com sucesso.'
)
prop4_items = [
  { name: 'Amortecedor Traseiro E — Hilux',           code: 'AT-HIL-E',  price: 380.00, quantity: 1, discount: 0,  total_value: 380.00, category_id: CAT_PECAS,    brand: 'Monroe', warranty_period: 365 },
  { name: 'Mão de obra — Alinhamento e balanceamento', code: 'MO-ALINH',  price: 150.00, quantity: 1, discount: 0,  total_value: 150.00, category_id: CAT_SERVICOS, warranty_period: 30 },
  { name: 'Mão de obra — Substituição amortecedor',    code: 'MO-AMORT',  price: 200.00, quantity: 1, discount: 10, total_value: 180.00, category_id: CAT_SERVICOS, warranty_period: 30 },
]
create_proposal_items(prop4.id, prop4_items)
puts "[PoC]   Proposta ##{prop4.id} — Fornecedor 2 para #{os4.code} (PAGA, R$ 710,00)"

# OS Histórica — proposta PAGA do Fornecedor 1 para POC-0001 (referência para "Reaproveitar")
prop_hist = OrderServiceProposal.create!(
  order_service_id:                 os_hist.id,
  provider_id:                      fornecedor1.id,
  order_service_proposal_status_id: PROP_STATUS_PAGA,
  total_value:                      465.00,
  total_value_without_discount:     465.00,
  details:                          'Substituição completa de pastilhas dianteiras e traseiras com peças originais.'
)
prop_hist_items = [
  { name: 'Pastilha de Freio Dianteira — Gol G6 (par)', code: 'PF-GOL-D', price: 145.00, quantity: 1, discount: 0, total_value: 145.00, category_id: CAT_PECAS,    brand: 'Fras-le',  warranty_period: 365 },
  { name: 'Pastilha de Freio Traseira — Gol G6 (par)',  code: 'PF-GOL-T', price: 98.00,  quantity: 1, discount: 0, total_value: 98.00,  category_id: CAT_PECAS,    brand: 'Fras-le',  warranty_period: 365 },
  { name: 'Fluido de Freio DOT 4 (500ml)',               code: 'FF-DOT4',  price: 42.00,  quantity: 1, discount: 0, total_value: 42.00,  category_id: CAT_PECAS,    brand: 'Bosch',    warranty_period: 180 },
  { name: 'Mão de obra — Troca de pastilhas (4 rodas)',  code: 'MO-PAST',  price: 180.00, quantity: 1, discount: 0, total_value: 180.00, category_id: CAT_SERVICOS, warranty_period: 30 },
]
create_proposal_items(prop_hist.id, prop_hist_items)
puts "[PoC]   Proposta ##{prop_hist.id} — Fornecedor 1 para #{os_hist.code} (HISTÓRICA PAGA, R$ 465,00)"

# ---------------------------------------------------------------------------
# 11. WEBHOOK LOGS (integração Portal Financeiro — Bloco 02)
# ---------------------------------------------------------------------------

puts "[PoC] Criando WebhookLogs..."

WebhookLog.create!(order_service_id: os3.id,    status: WebhookLog::SUCCESS, last_http_code: '200', attempts: 1, last_attempt_at: 2.days.ago,    succeeded_at: 2.days.ago)
WebhookLog.create!(order_service_id: os4.id,    status: WebhookLog::SUCCESS, last_http_code: '200', attempts: 1, last_attempt_at: 1.month.ago,   succeeded_at: 1.month.ago)
WebhookLog.create!(order_service_id: os_hist.id, status: WebhookLog::SUCCESS, last_http_code: '200', attempts: 1, last_attempt_at: 3.months.ago, succeeded_at: 3.months.ago)
WebhookLog.create!(order_service_id: os1.id,    status: WebhookLog::FAILED,  last_http_code: '503', attempts: 3, last_attempt_at: 1.hour.ago,    last_error: 'Connection timeout — Portal Financeiro indisponível')
WebhookLog.create!(order_service_id: os2.id,    status: WebhookLog::PENDING, attempts: 0)
puts "[PoC]   5 WebhookLogs: 3 sucesso, 1 falha, 1 pendente"

# ---------------------------------------------------------------------------
# 12. AUDIT LOGS (gem audited — registros manuais para demo)
# ---------------------------------------------------------------------------

puts "[PoC] Criando registros de auditoria..."

# Logins simulados para todos os usuários
[admin, contratante, gestor, adicional, fornecedor1, fornecedor2].each_with_index do |u, i|
  Audited::Audit.create!(
    auditable_type:  'Session',
    auditable_id:    u.id,
    user_id:         u.id,
    action:          'login',
    audited_changes: { 'session' => ['', 'iniciada'] },
    remote_address:  "10.0.#{rand(1..10)}.#{rand(10..250)}",
    created_at:      (i + 1).days.ago
  )
end

# Logout simulado para gestor
Audited::Audit.create!(
  auditable_type:  'Session',
  auditable_id:    gestor.id,
  user_id:         gestor.id,
  action:          'logout',
  audited_changes: { 'session' => ['iniciada', 'encerrada'] },
  remote_address:  '10.0.1.10',
  created_at:      3.hours.ago
)

# Tentativa de login falha (para demo de segurança)
Audited::Audit.create!(
  auditable_type:  'Session',
  auditable_id:    0,
  user_id:         nil,
  action:          'login',
  audited_changes: { 'session' => ['', 'falha'], 'email' => 'tentativa@hackeada.com' },
  remote_address:  '189.45.123.77',
  created_at:      12.hours.ago
)

# Criação das OS
[os1, os2, os3, os4, os5, os_hist].each do |os|
  Audited::Audit.create!(
    auditable_type:  'OrderService',
    auditable_id:    os.id,
    user_id:         gestor.id,
    action:          'create',
    audited_changes: { 'order_service_status_id' => [nil, os.order_service_status_id] },
    remote_address:  '10.0.1.10',
    created_at:      os.created_at
  )
end

# Aprovação de proposta (OS3)
Audited::Audit.create!(
  auditable_type:  'OrderServiceProposal',
  auditable_id:    prop3.id,
  user_id:         gestor.id,
  action:          'update',
  audited_changes: { 'order_service_proposal_status' => ['Em cadastro', 'Aprovada'] },
  remote_address:  '10.0.1.10',
  created_at:      3.days.ago
)

total_audits = 6 + 1 + 1 + 5 + 1
puts "[PoC]   #{total_audits} registros de auditoria criados"

# ---------------------------------------------------------------------------
# 13. NOTIFICAÇÕES (painel de notificações — sino e popup)
# ---------------------------------------------------------------------------

puts "[PoC] Criando notificações..."

gestor_profile_id    = Profile::MANAGER_ID
fornecedor_profile_id = Profile::PROVIDER_ID

# 1. Global — todos os perfis — Sino + Popup — Importante
notif1 = Notification.create!(
  title:       '[PoC] Atualização do sistema — versão 3.12.0 disponível',
  message:     'O sistema foi atualizado com melhorias de desempenho e novas funcionalidades: histórico de preços por veículo, relatórios aprimorados e correções de segurança. Acesse o painel para verificar as novidades.',
  profile_id:  nil,
  send_all:    true,
  display_type: Notification::DISPLAY_BOTH,
  is_important: true,
  created_at:  2.days.ago
)

# 2. Gestor — Sino — Importante: proposta recebida aguardando avaliação
notif2 = Notification.create!(
  title:       '[PoC] Nova proposta recebida — ação necessária',
  message:     "A OS #{os2.code} (#{v1.board}) recebeu 2 propostas concorrentes e está aguardando sua avaliação. Acesse o painel para comparar os valores e aprovar a proposta mais vantajosa.",
  profile_id:  gestor_profile_id,
  send_all:    true,
  display_type: Notification::DISPLAY_BELL,
  is_important: true,
  created_at:  1.day.ago
)

# 3. Fornecedor — Popup: nova OS disponível na região
notif3 = Notification.create!(
  title:       '[PoC] Nova OS disponível para cotação',
  message:     "Uma nova Ordem de Serviço (#{os1.code}) foi aberta para o veículo #{v1.board} e está disponível para sua empresa realizar uma proposta. Acesse o sistema para visualizar os detalhes.",
  profile_id:  fornecedor_profile_id,
  send_all:    true,
  display_type: Notification::DISPLAY_POPUP,
  is_important: false,
  created_at:  3.hours.ago
)

# 4. Global — todos — Sino: manutenção programada
notif4 = Notification.create!(
  title:       '[PoC] Manutenção programada do sistema — 18/05/2026 às 02h',
  message:     'Informamos que o sistema passará por manutenção preventiva no dia 18/05/2026 das 02h00 às 04h00. Durante este período, o acesso poderá ficar intermitente. Salve seus trabalhos antes do horário indicado.',
  profile_id:  nil,
  send_all:    true,
  display_type: Notification::DISPLAY_BELL,
  is_important: false,
  created_at:  5.hours.ago
)

# 5. Gestor — Sino: anomalia crítica detectada no checklist
notif5 = Notification.create!(
  title:       '[PoC] Anomalia crítica detectada — POC-0001',
  message:     "O checklist do veículo #{v1.board} (POC-0001) registrou anomalia CRÍTICA no item Pastilha de Freio Dianteira. O problema foi reconhecido pelo gestor e a OS #{os1.code} foi aberta para tratamento. Acompanhe o andamento.",
  profile_id:  gestor_profile_id,
  send_all:    true,
  display_type: Notification::DISPLAY_BELL,
  is_important: false,
  created_at:  4.days.ago
)

puts "[PoC]   5 notificações criadas (2 globais, 2 gestor, 1 fornecedor)"
puts "[PoC]   Tipos: 1 popup+sino, 2 sino, 1 popup, 1 sino | 2 importantes"

# ---------------------------------------------------------------------------
# 15. RELATÓRIO FINAL
# ---------------------------------------------------------------------------

puts ""
puts "=" * 70
puts "SEED DE PoC CONCLUÍDO — #{Time.current.strftime('%d/%m/%Y %H:%M:%S')}"
puts "=" * 70
puts ""
puts "CREDENCIAIS (senha única: PoC@2025!)"
puts "-" * 70
puts "  ADMIN:        poc.admin@frotademo.gov.br"
puts "  CONTRATANTE:  poc.contratante@frotademo.gov.br"
puts "  GESTOR:       poc.gestor@frotademo.gov.br"
puts "  ADICIONAL:    poc.adicional@frotademo.gov.br"
puts "  FORNECEDOR 1: poc.fornecedor1@autopecastotal.com.br"
puts "  FORNECEDOR 2: poc.fornecedor2@mecanicaprecisa.com.br"
puts ""
puts "VEÍCULOS"
puts "-" * 70
puts "  #{v1.board} — #{v1.brand} #{v1.model} #{v1.year}  (id=#{v1.id})"
puts "  #{v2.board} — #{v2.brand} #{v2.model} #{v2.year}  (id=#{v2.id})"
puts "  #{v3.board} — #{v3.brand} #{v3.model} #{v3.year}  (id=#{v3.id})"
puts ""
puts "ORDENS DE SERVIÇO"
puts "-" * 70
puts "  #{os1.code}   — EM ABERTO            (#{v1.board}) — direcionada ao Fornecedor 1"
puts "  #{os2.code}   — AGUARDANDO AVALIAÇÃO (#{v1.board}) — 2 propostas concorrentes"
puts "  #{os3.code}   — APROVADA             (#{v2.board}) — proposta aprovada + webhook OK"
puts "  #{os4.code}   — PAGA                 (#{v3.board}) — ciclo completo"
puts "  #{os5.code}   — CANCELADA            (#{v2.board})"
puts "  #{os_hist.code} — HISTÓRICA PAGA     (#{v1.board}) — referência para Reaproveitar Orçamento"
puts ""
puts "API KEYS (API V2)"
puts "-" * 70
api_keys.each { |email, token| puts "  #{email}:\n    #{token}" }
puts ""
puts "RESUMO DOS DADOS"
puts "-" * 70
puts "  Audit logs:    #{Audited::Audit.count} registros"
puts "  Veículos:      #{Vehicle.where(client_id: contratante.id).count}"
puts "  OS:            #{OrderService.where(client_id: contratante.id).count}"
puts "  Checklists:    #{VehicleChecklist.where(client_id: contratante.id).count} (1 com anomalia crítica)"
puts "  KM Records:    #{VehicleKmRecord.where(vehicle_id: [v1.id, v2.id, v3.id]).count}"
puts "  WebhookLogs:   #{WebhookLog.count} (#{WebhookLog.success.count} OK / #{WebhookLog.failed.count} falha / #{WebhookLog.pending.count} pendente)"
puts "  Notificações:  #{Notification.where('title LIKE ?', '%[PoC]%').count} criadas (#{Notification.where('title LIKE ? AND is_important = 1', '%[PoC]%').count} importantes)"
puts ""
puts "ROTEIRO RÁPIDO DA DEMONSTRAÇÃO"
puts "-" * 70
puts "  1. Login GESTOR → dashboard com #{OrderService.where(client_id: contratante.id).count} OS"
puts "  2. #{os2.code} → avaliar 2 propostas (R$394 vs R$300)"
puts "  3. Aprovar proposta Fornecedor 1 → OS muda para APROVADA"
puts "  4. Login FORNECEDOR 1 → criar proposta para #{os1.code} (reaproveitar orçamento)"
puts "  5. #{v1.board} → checklist com anomalia crítica em freios"
puts "  6. /audit_logs → filtrar por Login, exportar CSV e PDF"
puts "  7. /custom_reports → filtro período + Demonstrativo PDF"
puts "  8. /financial_portal → SSO + webhook logs (#{os3.code}: OK / #{os1.code}: falha)"
puts "  9. /performance_benchmark → todos os tempos < 2.000 ms"
puts " 10. API V2 → curl com Bearer token do Fornecedor 1"
puts "=" * 70
