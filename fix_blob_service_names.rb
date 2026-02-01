puts '=== Verificando service_name dos blobs ==='

local_count = ActiveStorage::Blob.where(service_name: 'local').count
disk_count = ActiveStorage::Blob.where(service_name: 'disk').count
amazon_count = ActiveStorage::Blob.where(service_name: 'amazon').count
nil_count = ActiveStorage::Blob.where(service_name: nil).count

puts "Blobs com service_name 'local': #{local_count}"
puts "Blobs com service_name 'disk': #{disk_count}"
puts "Blobs com service_name 'amazon': #{amazon_count}"
puts "Blobs com service_name NULL: #{nil_count}"
puts "Total de blobs: #{ActiveStorage::Blob.count}"

if local_count > 0 || disk_count > 0 || nil_count > 0
  puts "\n⚠️ PROBLEMA ENCONTRADO: Há blobs com service_name incorreto!"
  puts "\n=== Corrigindo service_name para 'amazon' ==="
  
  updated = 0
  
  # Corrigir blobs com 'local'
  if local_count > 0
    ActiveStorage::Blob.where(service_name: 'local').update_all(service_name: 'amazon')
    updated += local_count
    puts "✓ #{local_count} blobs atualizados de 'local' para 'amazon'"
  end
  
  # Corrigir blobs com 'disk'
  if disk_count > 0
    ActiveStorage::Blob.where(service_name: 'disk').update_all(service_name: 'amazon')
    updated += disk_count
    puts "✓ #{disk_count} blobs atualizados de 'disk' para 'amazon'"
  end
  
  # Corrigir blobs com NULL
  if nil_count > 0
    ActiveStorage::Blob.where(service_name: nil).update_all(service_name: 'amazon')
    updated += nil_count
    puts "✓ #{nil_count} blobs atualizados de NULL para 'amazon'"
  end
  
  puts "\n✅ Total de #{updated} blobs corrigidos!"
else
  puts "\n✅ Todos os blobs já estão com service_name 'amazon'!"
end
