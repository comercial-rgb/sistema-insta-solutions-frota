#!/usr/bin/env ruby
# Find OS codes for Bellenzier Pneus and Mecânica Schio
# Usage: RAILS_ENV=production rails runner scripts/find_bellenzier_schio.rb

OrderService.joins(order_service_proposals: :provider)
  .where("users.fantasy_name LIKE '%Bellenzier%' OR users.fantasy_name LIKE '%Schio%' OR users.social_name LIKE '%Bellenzier%' OR users.social_name LIKE '%Schio%'")
  .distinct
  .each do |os|
    proposal = os.approved_proposal
    next unless proposal
    provider = proposal.provider
    name = provider&.fantasy_name.presence || provider&.social_name.presence || 'SEM NOME'
    puts "OS: #{os.code}  ID: #{os.id}  Provider: #{name}  Status: #{os.order_service_status&.name}"
  end
