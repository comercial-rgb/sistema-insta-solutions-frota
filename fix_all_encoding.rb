#!/usr/bin/env ruby
# Script para corrigir encoding em TODAS as tabelas do sistema
# Executa correções UTF-8 para nomes, cidades, serviços, endereços, etc.

require_relative 'config/environment'

puts "🔧 CORRIGINDO ENCODING EM TODO O BANCO DE DADOS"
puts "=" * 80

# Mapeamento de caracteres corrompidos para corretos
# Baseado nos erros encontrados: Simêo -> Simão, Joêo -> João, Sêo -> São, etc.
ENCODING_FIXES = {
  # Padrões específicos de palavras comuns
  'Sêo' => 'São',
  'Joêo' => 'João',
  'Mêrio' => 'Mário',
  'Josê' => 'José',
  'Antênio' => 'Antônio',
  'Marêo' => 'Março',
  'Jêlio' => 'Júlio',
  'Goiês' => 'Goiás',
  'Venêncio' => 'Venâncio',
  'Amêrica' => 'América',
  'Brasêlia' => 'Brasília',
  'Belêm' => 'Belém',
  'Tarumê' => 'Tarumã',
  'Osêrio' => 'Osório',
  'Viêosa' => 'Viçosa',
  'Conceiêêo' => 'Conceição',
  'Providência' => 'Providência',
  'Marilêndia' => 'Marilândia',
  'Ceilêndia' => 'Ceilândia',
  'Rodoviêrio' => 'Rodoviário',
  'Junêêo' => 'Junção',
  'Bonifêcio' => 'Bonifácio',
  'Exposiêêo' => 'Exposição',
  'Econêmico' => 'Econômico',
  'Paraêso' => 'Paraíso',
  'Rosêrio' => 'Rosário',
  'Fêtima' => 'Fátima',
  'Barêo' => 'Barão',
  'Cêndido' => 'Cândido',
  'Olêmpio' => 'Olímpio',
  'Capitêo' => 'Capitão',
  'Naêêes' => 'Nações',
  'êngelo' => 'Ângelo',
  'Tristêo' => 'Tristão',
  'Irmêos' => 'Irmãos',
  'Uniêo' => 'União',
  'Adalberto Simêo' => 'Adalberto Simão',
  'Florêncio' => 'Florêncio',
  'Elesbêo' => 'Elesbão',
  'Desembargador Mêrio' => 'Desembargador Mário',
  'Sêrgio Rogêrio' => 'Sérgio Rogério',
  'Ferrabrês' => 'Ferrabrás',
  'Theodorico Ferraêo' => 'Theodorico Ferrão',
  'Jêronimo' => 'Jerônimo',
  'Euzêbio' => 'Euzébio',
  'Cristêvêo' => 'Cristóvão',
  'Boqueirêo' => 'Boqueirão',
  'Cerêmica' => 'Cerâmica',
  'Esquina Brandêo' => 'Esquina Brandão',
  'Girêo' => 'Girão',
  'Sêtio' => 'Sítio',
  
  # Cidades
  'Açãilãndia' => 'Açailândia',
  'Alcobaçã' => 'Alcobaça',
  'Aliançã' => 'Aliança',
  'Garçãs' => 'Garças',
  'Araçãã' => 'Araçaí',
  'Araçãgi' => 'Araçagi',
  'Araçãriguama' => 'Araçariguama',
  'Araçãs' => 'Araças',
  'Araçãtuba' => 'Araçatuba',
  'Aragarçãs' => 'Aragarças',
  'Augusto Corrçã' => 'Augusto Corrêa',
  'Baçã da Traiâo' => 'Baía da Traição',
  'Baçã Formosa' => 'Baía Formosa',
  'Balneãrio Piçãrras' => 'Balneário Piçarras',
  'Barra do Choçã' => 'Barra do Choça',
  'Barra do Garçãs' => 'Barra do Garças',
  'Boa Esperançã' => 'Boa Esperança',
  'Boa Esperançã do Iguaçul' => 'Boa Esperança do Iguaçu',
  'Boa Esperançã do Sul' => 'Boa Esperança do Sul',
  'Bragançã' => 'Bragança',
  'Bragançã Paulista' => 'Bragança Paulista',
  'Caçãdor' => 'Caçador',
  'Caçãpava' => 'Caçapava',
  'Caçãpava do Sul' => 'Caçapava do Sul',
  'Caiçãra' => 'Caiçara',
  'Caiçãra do Norte' => 'Caiçara do Norte',
  'Caiçãra do Rio do Vento' => 'Caiçara do Rio do Vento',
  'Calçãdo' => 'Calçado',
  'Camaçãri' => 'Camaçari',
  'Capitão Ençãs' => 'Capitão Enéas',
  'Cirçãco' => 'Ciriaco',
  'Conceição' => 'Conceição',
  'Ençãs Marques' => 'Enéas Marques',
  'Esperançã' => 'Esperança',
  'Esperançã do Sul' => 'Esperança do Sul',
  'Esperançã Nova' => 'Esperança Nova',
  'Garçã' => 'Garça',
  'Graçã' => 'Graça',
  'Graçã Aranha' => 'Graça Aranha',
  'Guaiçãra' => 'Guaiçara',
  'Guaraçãã' => 'Guaraçaí',
  'Guaraqueçãba' => 'Guaraqueçaba',
  'Içãra' => 'Içara',
  'Isaçãs Coelho' => 'Isaías Coelho',
  'Itaiçãba' => 'Itaiçaba',
  'Jaçãnã' => 'Jaçanã',
  'Joaçãba' => 'Joaçaba',
  'Maçãmbara' => 'Maçambará',
  'Mendonçã' => 'Mendonça',
  'Mombaçã' => 'Mombaça',
  'Morro Cabeçã no Tempo' => 'Morro Cabeça no Tempo',
  'Morro da Fumaçã' => 'Morro da Fumaça',
  'Morro da Garçã' => 'Morro da Garça',
  'Nilo Peçãnha' => 'Nilo Peçanha',
  'Nossa Senhora das Graçãs' => 'Nossa Senhora das Graças',
  'Nova Aliançã' => 'Nova Aliança',
  'Nova Aliançã do Ivaã' => 'Nova Aliança do Ivaí',
  'Nova Esperançã' => 'Nova Esperança',
  'Nova Esperançã do Piriã' => 'Nova Esperança do Piriá',
  'Nova Esperançã do Sudoeste' => 'Nova Esperança do Sudoeste',
  'Nova Esperançã do Sul' => 'Nova Esperança do Sul',
  'Olivençã' => 'Olivença',
  'Onçã de Pitangui' => 'Onça de Pitangui',
  'Ouriçãngas' => 'Ouriçangas',
  'Paiçãndu' => 'Paiçandu',
  'Palhoçã' => 'Palhoça',
  'Peçãnha' => 'Peçanha',
  'Pejuçãra' => 'Pejuçara',
  'Piaçãbuul' => 'Piaçabuçu',
  'Piçãrra' => 'Piçarra',
  'Rebouçãs' => 'Rebouças',
  'Renascençã' => 'Renascença',
  'Rio da Conceição' => 'Rio da Conceição',
  'Santa Cruz da Conceição' => 'Santa Cruz da Conceição',
  'Santa Cruz da Esperançã' => 'Santa Cruz da Esperança',
  "São João d'Aliançã" => "São João d'Aliança",
  'São Josã do Calçãdo' => 'São José do Calçado',
  'São Paulo de Olivençã' => 'São Paulo de Olivença',
  'São Sebastião de Lagoa de Roçã' => 'São Sebastião de Lagoa de Roça',
  'Serafina Corrçã' => 'Serafina Corrêa',
  'Valençã' => 'Valença',
  'Valençã do Piauã' => 'Valença do Piauí',
  'Vãrzea da Roçã' => 'Várzea da Roça',
  'Zortçã' => 'Zorteá',
  
  # Services
  'cedação' => 'vedação',
  'bujóo' => 'bujão',
  'IGNIÇÃO' => 'IGNIÇÃO',
  'DIREÇÃO' => 'DIREÇÃO',
  'direção' => 'direção',
  'INSTALAÇÃO' => 'INSTALAÇÃO',
  'instalação' => 'instalação',
  'INSPEÇÃO' => 'INSPEÇÃO',
  'inspeção' => 'inspeção',
  'tração' => 'tração',
  'TRANSPORTE  ESCOLAR' => 'TRANSPORTE ESCOLAR',
  'CARCAóA' => 'CARCAÇA',
  'scaner' => 'scanner',
  'Remoção' => 'Remoção',
  'diagnóstico' => 'diagnóstico',
  'diagnostico' => 'diagnóstico',
  'cabeóote' => 'cabeçote',
  'FUNILARIA' => 'FUNILARIA',
  'FERRIGEM' => 'FERRUGEM',
  'CHAPEAMENTO' => 'CHAPEAMENTO',
  'PARABRISA' => 'PARABRISA',
  'MÃO DE OBRA' => 'MÃO DE OBRA',
  'RETIRADA E INSTALAÇÃO' => 'RETIRADA E INSTALAÇÃO',
  'INSTALçO E INSTALAÇÃOCOM COM TROCA' => 'INSTALAÇÃO E TROCA',
  'AREFECIMENTO' => 'ARREFECIMENTO',
  'oxi-sanitização' => 'oxi-sanitização',
  'higienização' => 'higienização',
  'cartóo de higienização' => 'cartão de higienização',
  'Programação' => 'Programação',
  'VISTORIA E INSPEÇÃO' => 'VISTORIA E INSPEÇÃO',
  'MECANICA' => 'MECÂNICA',
  
  # Provider service types
  'Aquisição' => 'Aquisição',
  'Solicitação' => 'Solicitação',
  'Vitrificação' => 'Vitrificação',
  'Manutenção' => 'Manutenção',
  
  # Sub units
  'Três' => 'Três',
  'Educação' => 'Educação',
  'Universitário' => 'Universitário',
  'Assistência' => 'Assistência',
  'Saúde' => 'Saúde',
  'Hospitalar' => 'Hospitalar',
  'Atenção' => 'Atenção',
  'Básica' => 'Básica',
  'Bolsa Família' => 'Bolsa Família',
  'Ensino Fundamental' => 'Ensino Fundamental',
  'Ensino Superior' => 'Ensino Superior',
  'Ensino Infantil' => 'Ensino Infantil',
  
  # Users
  'Integração' => 'Integração',
  'Inspeção' => 'Inspeção',
  'Exportação' => 'Exportação',
  'Importação' => 'Importação',
  'Coordenação' => 'Coordenação',
  'Aperfeiãoamento' => 'Aperfeiçoamento',
  'Nóvel' => 'Nível',
  'Superintendência' => 'Superintendência',
  'Geografia e Estatóstica' => 'Geografia e Estatística',
  'Veóculos' => 'Veículos',
  'Educação' => 'Educação',
  'Manutenção' => 'Manutenção',
  'Chapeação' => 'Chapeação',
  'Tecnologia em Injeção' => 'Tecnologia em Injeção',
  'Remoção' => 'Remoção',
  'Servióos de Remoção' => 'Serviços de Remoção'
}

def fix_text(text)
  return text if text.blank?
  
  fixed = text.dup
  
  ENCODING_FIXES.each do |wrong, correct|
    fixed = fixed.gsub(wrong, correct)
  end
  
  fixed
end

def fix_table(table_name, columns, dry_run: false)
  puts "\n📋 #{dry_run ? 'SIMULANDO' : 'CORRIGINDO'} tabela: #{table_name}"
  puts "-" * 80
  
  fixed_count = 0
  
  begin
    model_class = table_name.classify.constantize rescue nil
    
    if model_class.nil?
      puts "⚠️  Model não encontrado para #{table_name}, pulando..."
      return 0
    end
    
    columns.each do |column|
      puts "  Processando coluna: #{column}..."
      
      # Buscar registros que precisam de correção
      model_class.where.not(column => nil).find_each do |record|
        original = record.send(column)
        next if original.blank?
        
        fixed = fix_text(original)
        
        if fixed != original
          if dry_run
            puts "    [DRY-RUN] ID #{record.id}: #{original[0..50]}... → #{fixed[0..50]}..."
          else
            record.update_column(column, fixed)
            puts "    ✓ ID #{record.id}: #{original[0..50]}... → #{fixed[0..50]}..."
          end
          fixed_count += 1
        end
      end
    end
    
    if fixed_count > 0
      puts "  ✅ #{fixed_count} registros #{dry_run ? 'precisam de' : 'foram'} corrigido(s)"
    else
      puts "  ℹ️  Nenhum registro precisou de correção"
    end
    
  rescue => e
    puts "  ⚠️  Erro: #{e.message}"
    puts e.backtrace.first(3)
  end
  
  fixed_count
end

# Definir tabelas e colunas para corrigir
TABLES_TO_FIX = {
  'users' => ['name', 'fantasy_name', 'social_name'],
  'cities' => ['name'],
  'services' => ['name', 'description', 'brand'],
  'addresses' => ['address', 'district', 'complement'],
  'provider_service_types' => ['name'],
  'sub_units' => ['name']
}

# Pergunta para usuário se quer executar ou apenas simular
puts "\n⚠️  ATENÇÃO: Este script irá modificar dados no banco de produção!"
puts "\n1️⃣  Digite 'SIM' para EXECUTAR as correções"
puts "2️⃣  Digite 'SIMULAR' para apenas VER o que seria corrigido"
puts "3️⃣  Digite qualquer outra coisa para CANCELAR\n"
print "\nOpção: "

option = STDIN.gets.chomp.upcase

case option
when 'SIM'
  dry_run = false
  puts "\n🚀 EXECUTANDO CORREÇÕES...\n"
when 'SIMULAR'
  dry_run = true
  puts "\n👀 SIMULANDO CORREÇÕES (nada será alterado)...\n"
else
  puts "\n❌ CANCELADO pelo usuário"
  exit
end

total_fixed = 0

TABLES_TO_FIX.each do |table, columns|
  fixed = fix_table(table, columns, dry_run: dry_run)
  total_fixed += fixed
end

puts "\n" + "=" * 80
puts "📊 RESUMO FINAL"
puts "=" * 80

if dry_run
  puts "\n👀 SIMULAÇÃO CONCLUÍDA"
  puts "#{total_fixed} registros PRECISAM de correção"
  puts "\nExecute novamente e digite 'SIM' para aplicar as correções."
else
  puts "\n✅ CORREÇÕES APLICADAS COM SUCESSO!"
  puts "#{total_fixed} registros foram corrigidos no banco de dados"
  puts "\nAs alterações foram salvas diretamente no banco de produção."
end

puts "\n"
