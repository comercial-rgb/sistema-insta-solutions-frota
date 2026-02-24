-- Query OS que estão no Frota mas NÃO no Financeiro
-- Grupo 2: Autorizadas no mês 02 (lista salmão)
SELECT os.id, os.code, os.order_service_status_id, oss.name as status_name, 
       os.created_at, os.updated_at
FROM order_services os 
JOIN order_service_statuses oss ON oss.id = os.order_service_status_id 
WHERE os.code IN (
  'OS42152025917','OS4219220251021','OS42432025122',
  'OS4243720251124','OS4248520251217','OS4249420251219',
  'OS4250520251223','OS4251120251229','OS4254520251230',
  'OS4254620251230','OS4254820251230','OS4256120251230',
  'OS425742026112','OS427302026126','OS427482026127',
  'OS427532026128','OS427902026128','OS428272026130',
  'OS420835202622','OS420843202623'
) ORDER BY os.updated_at;
