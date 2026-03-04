#!/usr/bin/env ruby
# Broader search for these numbers
numbers = ["42130", "42137", "42553", "42577", "42210"]

# Search in code field with LIKE
puts "--- Search by code LIKE ---"
numbers.each do |n|
  results = OrderService.unscoped.where("code LIKE ?", "%#{n}%")
  if results.any?
    results.each do |os|
      puts "  Found: id=#{os.id}, code=#{os.code}, status=#{os.order_service_status_id}"
    end
  end
end

# Search by provider_id
puts "\n--- Search by provider_id ---"
numbers.map(&:to_i).each do |n|
  count = OrderService.unscoped.where(provider_id: n).count
  puts "  Provider #{n}: #{count} OS" if count > 0
end

# Search in order_service_proposals
puts "\n--- Search proposal IDs ---"
numbers.map(&:to_i).each do |n|
  p = OrderServiceProposal.unscoped.find_by(id: n)
  if p
    puts "  Proposal #{n}: os_id=#{p.order_service_id}, status=#{p.order_service_proposal_status_id}, provider=#{p.provider_id}"
  end
end

# Check generate_code method
puts "\n--- Code generation sample ---"
os = OrderService.unscoped.last
puts "  Last OS: id=#{os.id}, code=#{os.code}, client_id=#{os.client_id}"

# Maybe they're using a sequential numbering visible in UI?
# Let me check if there's a `number` or `sequential` column
puts "\n--- OS columns ---"
puts OrderService.column_names.join(", ")

# Check user IDs for these providers
puts "\n--- Search User IDs ---"
numbers.map(&:to_i).each do |n|
  u = User.unscoped.find_by(id: n)
  if u
    puts "  User #{n}: #{u.name}, profile=#{u.profile_id}"
  end
end
