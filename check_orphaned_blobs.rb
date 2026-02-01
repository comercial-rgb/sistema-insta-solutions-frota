#!/usr/bin/env ruby
# Verifica blobs órfãos (sem arquivo no disco e sem arquivo no S3)

service = ActiveStorage::Blob.service
blobs = ActiveStorage::Blob.all
total = blobs.count

missing_local = 0
missing_s3 = 0
ok = 0

puts "Verificando #{total} blobs..."
puts

blobs.each_with_index do |blob, index|
  local_path = Rails.root.join('storage', blob.key[0..1], blob.key[2..3], blob.key)
  exists_local = File.exist?(local_path)
  
  begin
    exists_s3 = service.exist?(blob.key)
  rescue
    exists_s3 = false
  end
  
  if !exists_local && !exists_s3
    missing_local += 1
    missing_s3 += 1
    puts "[#{index + 1}/#{total}] ✗ ÓRFÃO: #{blob.filename} (ID: #{blob.id})"
  elsif !exists_s3
    missing_s3 += 1
  elsif exists_local && exists_s3
    ok += 1
  end
  
  print "\rProgresso: #{index + 1}/#{total}" if (index + 1) % 10 == 0
end

puts
puts
puts "=" * 60
puts "=== RESUMO ==="
puts "Total de blobs: #{total}"
puts "✓ OK (no disco e no S3): #{ok}"
puts "⚠️  Faltando no S3: #{missing_s3}"
puts "✗ Órfãos (sem arquivo): #{missing_local}"
puts "=" * 60
