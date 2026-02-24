-- Query OS que aparecem no Frota E no Financeiro (OK - para referência)
SELECT os.id, os.code, os.order_service_status_id, oss.name as status_name, 
       os.created_at, os.updated_at
FROM order_services os 
JOIN order_service_statuses oss ON oss.id = os.order_service_status_id 
WHERE os.code IN (
  'OS427402026127','OS428312026130',
  'OS420838202623','OS420839202623',
  'OS420857202626','OS420858202626','OS420877202629'
) ORDER BY os.updated_at;
