-- Query OS que estão no Frota mas NÃO no Financeiro
-- Grupo 1: Autorizadas no mês 01 (lista verde)
SELECT os.id, os.code, os.order_service_status_id, oss.name as status_name, 
       os.created_at, os.updated_at
FROM order_services os 
JOIN order_service_statuses oss ON oss.id = os.order_service_status_id 
WHERE os.code IN (
  'OS4228520251031','OS424142025121','OS424152025121',
  'OS4250720251223','OS4251320251229','OS4253220251230',
  'OS425712026112','OS4250820251226','OS4247820251216',
  'OS4234620251118','OS4254420251230','OS4253720251230',
  'OS4253120251230','OS4251220251229','OS4249120251218',
  'OS4246820251212','OS4246420251212','OS4246520251212'
) ORDER BY os.updated_at;
