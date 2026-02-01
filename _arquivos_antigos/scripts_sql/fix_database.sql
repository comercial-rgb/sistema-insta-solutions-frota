-- Script de correção completa do banco de dados
-- Aplica todas as alterações necessárias

-- 1. Adicionar coluna is_complement (erro que apareceu)
ALTER TABLE order_service_proposals ADD COLUMN is_complement TINYINT(1) DEFAULT 0;

-- 2. Colunas das 17 migrações
ALTER TABLE order_services ADD COLUMN service_group_id BIGINT;
ALTER TABLE order_services ADD COLUMN origin VARCHAR(255);
ALTER TABLE order_service_proposals ADD COLUMN justification TEXT;
ALTER TABLE order_service_proposals ADD COLUMN reason_refused_approval TEXT;
ALTER TABLE order_service_proposal_items ADD COLUMN observation TEXT;
ALTER TABLE order_service_proposal_items ADD COLUMN guarantee VARCHAR(255);
ALTER TABLE order_service_proposal_items ADD COLUMN warranty_start_date DATE;
ALTER TABLE part_service_order_services ADD COLUMN quantity INT DEFAULT 1;
ALTER TABLE contracts ADD COLUMN final_date DATE;

-- 3. Registrar as 17 migrações na tabela schema_migrations
INSERT IGNORE INTO schema_migrations (version) VALUES 
('20260108120002'), ('20260108120003'), ('20260108120004'), 
('20260110120000'), ('20260110222100'), ('20260111014152'), 
('20260111040000'), ('20260111050000'), ('20260113134437'), 
('20260113140658'), ('20260113144317'), ('20260113210700'), 
('20260114101357'), ('20260114120638'), ('20260120163811'), 
('20260120163843'), ('20260120163937');
