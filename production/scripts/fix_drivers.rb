# Corrigir drivers manualmente

conn = ActiveRecord::Base.connection

puts "Corrigindo campo driver..."

# Aplicar REPLACE direto
fixes = [
  ['??', 'í'],
  ['??', 'á'],
  ['??', 'é'],
  ['??', 'ó']
]

fixes.each do |wrong, correct|
  sql = "UPDATE order_services SET driver = REPLACE(driver, '#{wrong}', '#{correct}') WHERE driver LIKE '%??%'"
  conn.execute(sql)
end

# Verificar
remaining = conn.select_one("SELECT COUNT(*) as count FROM order_services WHERE driver LIKE '%??%'")

puts "Restantes: #{remaining['count']}"
