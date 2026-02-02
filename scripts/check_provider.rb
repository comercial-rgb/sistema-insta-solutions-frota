os = OrderService.find_by(code: 'OS327772026128')
puts "=" * 60
puts "Provider ID: #{os.provider_id}"
puts "Provider: #{os.provider.inspect}"
puts "Fantasy Name: '#{os.provider&.fantasy_name}'"
puts "Social Name: '#{os.provider&.social_name}'"
puts "=" * 60
