#!/usr/bin/env ruby
# Investigar OS não encontradas pelo code
# Uso: RAILS_ENV=production rails runner scripts/check_missing_os.rb

missing_codes = [
  'OS4254420251230',
  'OS4253720251230',
  'OS42432025122',
  'OS4243720251124',
  'OS4254520251230',
  'OS4254620251230',
  'OS4254820251230',
  'OS4256120251230',
]

puts "=" * 60
puts "INVESTIGACAO OS NAO ENCONTRADAS"
puts "=" * 60

missing_codes.each do |code|
  os = OrderService.find_by(code: code)
  if os
    puts "#{code}: ENCONTRADA (ID: #{os.id})"
  else
    puts "#{code}: NAO ENCONTRADA"
    
    # Try to extract potential ID from code
    # Format: OS{client_id}{id}{date}
    # client_id = 42, so remove OS42 prefix
    remainder = code.sub('OS42', '')
    
    # Try different ID lengths (3-4 digits after client_id)
    [3, 4].each do |id_len|
      if remainder.length >= id_len
        potential_id = remainder[0, id_len].to_i
        if potential_id > 0
          os_by_id = OrderService.find_by(id: potential_id)
          if os_by_id
            puts "  -> ID #{potential_id}: existe (code=#{os_by_id.code}, status=#{os_by_id.order_service_status&.name})"
          end
        end
      end
    end
    
    # Search by LIKE
    like_results = OrderService.where("code LIKE ?", "%#{code.sub('OS42', '42')}%").limit(3)
    like_results.each do |lr|
      puts "  -> LIKE match: ID=#{lr.id}, code=#{lr.code}"
    end
  end
end

# Also list all OS with IDs from 530-570 to see the patterns
puts "\n--- OS com IDs 530-570 ---"
OrderService.where(id: 530..570).order(:id).each do |os|
  puts "  ID=#{os.id} code=#{os.code} status=#{os.order_service_status&.name}"
end
