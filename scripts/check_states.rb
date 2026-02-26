State.order(:id).each do |s|
  puts "#{s.id}\t#{s.acronym}\t#{s.name}"
end

puts "\n--- Cost Center ID=5 ---"
cc = CostCenter.find(5)
puts "invoice_state_id: #{cc.invoice_state_id}"
puts "invoice_state: #{cc.invoice_state&.acronym} / #{cc.invoice_state&.name}"
