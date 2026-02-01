#!/usr/bin/env ruby
# encoding: UTF-8

require 'yaml'
require 'find'

# Padrões suspeitos de encoding incorreto
SUSPICIOUS_PATTERNS = [
  /ê[aeiou]/i,  # ê seguido de vogal
  /ô[aeiou]/i,  # ô seguido de vogal
  /Sêo/,        # São
  /Joêo/,       # João
  /Simêo/,      # Simão
  /Viêosa/,     # Viçosa
  /Mêrio/,      # Mário
  /çêo/,        # ção
  /ê\s/,        # ê seguido de espaço (pode ser problema)
  /ô\s/         # ô seguido de espaço
]

# Palavras legítimas que contém esses padrões
LEGITIMATE_WORDS = %w[
  três você português inglês francês mês mercês cortês
  robô vôo enjoo compôs repôs
]

results = {
  views: [],
  locales: [],
  helpers: [],
  models: [],
  controllers: []
}

def check_file_for_patterns(file_path)
  suspicious_lines = []
  
  begin
    File.readlines(file_path, encoding: 'UTF-8').each_with_index do |line, index|
      SUSPICIOUS_PATTERNS.each do |pattern|
        if line =~ pattern
          # Verifica se não é uma palavra legítima
          match_context = line.scan(/\b\w*#{pattern.source}\w*\b/)
          
          is_suspicious = match_context.any? do |word|
            !LEGITIMATE_WORDS.any? { |legit| word.downcase.include?(legit.downcase) }
          end
          
          if is_suspicious
            suspicious_lines << {
              line_number: index + 1,
              content: line.strip,
              pattern: pattern.source
            }
          end
        end
      end
    end
  rescue => e
    return { error: e.message }
  end
  
  suspicious_lines
end

def get_file_type(path)
  if path.include?('app/views')
    'view'
  elsif path.include?('config/locales')
    'locale'
  elsif path.include?('app/helpers')
    'helper'
  elsif path.include?('app/models')
    'model'
  elsif path.include?('app/controllers')
    'controller'
  else
    'other'
  end
end

puts "=" * 80
puts "ANÁLISE DE ENCODING EM ARQUIVOS COM TEXTO VISÍVEL AO USUÁRIO"
puts "=" * 80
puts ""

base_dir = File.expand_path('.')

# Procurar arquivos .erb (views)
puts "Analisando arquivos .erb (views)..."
Find.find("#{base_dir}/app/views") do |path|
  if FileTest.file?(path) && path.end_with?('.erb')
    suspicious = check_file_for_patterns(path)
    relative_path = path.sub(base_dir + '/', '')
    
    results[:views] << {
      path: relative_path,
      has_suspicious: !suspicious.empty?,
      suspicious_lines: suspicious
    }
  end
end rescue nil

# Procurar arquivos de locale
puts "Analisando arquivos de locale (.yml)..."
Find.find("#{base_dir}/config/locales") do |path|
  if FileTest.file?(path) && path.end_with?('.yml')
    suspicious = check_file_for_patterns(path)
    relative_path = path.sub(base_dir + '/', '')
    
    results[:locales] << {
      path: relative_path,
      has_suspicious: !suspicious.empty?,
      suspicious_lines: suspicious
    }
  end
end rescue nil

# Procurar arquivos de helpers
puts "Analisando arquivos de helpers (.rb)..."
Find.find("#{base_dir}/app/helpers") do |path|
  if FileTest.file?(path) && path.end_with?('.rb')
    suspicious = check_file_for_patterns(path)
    relative_path = path.sub(base_dir + '/', '')
    
    results[:helpers] << {
      path: relative_path,
      has_suspicious: !suspicious.empty?,
      suspicious_lines: suspicious
    }
  end
end rescue nil

# Procurar arquivos de models
puts "Analisando arquivos de models (.rb)..."
Find.find("#{base_dir}/app/models") do |path|
  if FileTest.file?(path) && path.end_with?('.rb')
    suspicious = check_file_for_patterns(path)
    relative_path = path.sub(base_dir + '/', '')
    
    results[:models] << {
      path: relative_path,
      has_suspicious: !suspicious.empty?,
      suspicious_lines: suspicious
    }
  end
end rescue nil

# Procurar arquivos de controllers
puts "Analisando arquivos de controllers (.rb)..."
Find.find("#{base_dir}/app/controllers") do |path|
  if FileTest.file?(path) && path.end_with?('.rb')
    suspicious = check_file_for_patterns(path)
    relative_path = path.sub(base_dir + '/', '')
    
    results[:controllers] << {
      path: relative_path,
      has_suspicious: !suspicious.empty?,
      suspicious_lines: suspicious
    }
  end
end rescue nil

puts ""
puts "=" * 80
puts "RELATÓRIO DE RESULTADOS"
puts "=" * 80
puts ""

# Arquivos com padrões suspeitos
puts "### ARQUIVOS COM PADRÕES SUSPEITOS DE ENCODING ###"
puts ""

[:views, :locales, :helpers, :models, :controllers].each do |type|
  suspicious_files = results[type].select { |f| f[:has_suspicious] }
  
  if suspicious_files.any?
    puts "## #{type.to_s.upcase} (#{suspicious_files.count} arquivo(s))"
    puts ""
    
    suspicious_files.each do |file|
      puts "❌ #{file[:path]}"
      file[:suspicious_lines].each do |line|
        puts "   Linha #{line[:line_number]}: #{line[:content][0..100]}"
        puts "   Padrão: #{line[:pattern]}"
      end
      puts ""
    end
  end
end

# Lista completa de arquivos por tipo
puts ""
puts "=" * 80
puts "### LISTA COMPLETA DE ARQUIVOS POR TIPO ###"
puts "=" * 80
puts ""

[:views, :locales, :helpers, :models, :controllers].each do |type|
  puts "## #{type.to_s.upcase} (#{results[type].count} arquivo(s))"
  puts ""
  
  results[type].sort_by { |f| f[:path] }.each do |file|
    status = file[:has_suspicious] ? "❌ SUSPEITO" : "✓ OK"
    puts "#{status} - #{file[:path]}"
  end
  
  puts ""
end

# Resumo
puts "=" * 80
puts "RESUMO"
puts "=" * 80
puts ""
puts "Total de arquivos analisados:"
results.each do |type, files|
  suspicious_count = files.count { |f| f[:has_suspicious] }
  puts "  #{type.to_s.capitalize}: #{files.count} (#{suspicious_count} suspeitos)"
end

puts ""
puts "Análise concluída!"
