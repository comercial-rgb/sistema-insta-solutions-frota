#!/usr/bin/env ruby
# encoding: UTF-8

require 'find'
require 'json'

results = {
  views: [],
  locales: [],
  helpers: [],
  models: [],
  controllers: []
}

base_dir = File.expand_path('.')

# Views
Find.find("#{base_dir}/app/views") do |path|
  if FileTest.file?(path) && path.end_with?('.erb')
    results[:views] << path.sub(base_dir + '/', '')
  end
end rescue nil

# Locales
Find.find("#{base_dir}/config/locales") do |path|
  if FileTest.file?(path) && path.end_with?('.yml')
    results[:locales] << path.sub(base_dir + '/', '')
  end
end rescue nil

# Helpers
Find.find("#{base_dir}/app/helpers") do |path|
  if FileTest.file?(path) && path.end_with?('.rb')
    results[:helpers] << path.sub(base_dir + '/', '')
  end
end rescue nil

# Models
Find.find("#{base_dir}/app/models") do |path|
  if FileTest.file?(path) && path.end_with?('.rb')
    results[:models] << path.sub(base_dir + '/', '')
  end
end rescue nil

# Controllers
Find.find("#{base_dir}/app/controllers") do |path|
  if FileTest.file?(path) && path.end_with?('.rb')
    results[:controllers] << path.sub(base_dir + '/', '')
  end
end rescue nil

File.write('file_listing.json', JSON.pretty_generate(results))

puts "RESUMO DE ARQUIVOS COM TEXTO VISÍVEL AO USUÁRIO"
puts "=" * 60
puts ""
puts "Views (.erb):       #{results[:views].count} arquivos"
puts "Locales (.yml):     #{results[:locales].count} arquivos"
puts "Helpers (.rb):      #{results[:helpers].count} arquivos"
puts "Models (.rb):       #{results[:models].count} arquivos"
puts "Controllers (.rb):  #{results[:controllers].count} arquivos"
puts ""
puts "Total:              #{results.values.flatten.count} arquivos"
puts ""
puts "Detalhes salvos em: file_listing.json"
