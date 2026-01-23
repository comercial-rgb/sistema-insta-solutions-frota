# Correção manual direta de encoding

ActiveRecord::Base.transaction do
  corrections = {
    296 => 'Kátia Regina Mallmann Demeterko',
    331 => 'Líder Despachante LTDA',
    353 => 'AMR Peças e Equipamentos Hidráulicos Eireli',
    361 => 'Auto Eletrica São João',
    366 => 'Vitran Inspeção Veicular LTDA',
    401 => 'Oficina União LTDA',
    404 => 'Mecanica Irmãos Soella LTDA',
    410 => 'Posto de Molas Belém LTDA',
    482 => 'RFJ Soluções e Transportes LTDA',
    517 => 'Brasil SA Exportação Importação',
    543 => 'Rodonova Inspeções LTDA',
    587 => 'Expansão Auto Center LTDA',
    626 => 'ACS Soluções Agrícolas LTDA',
    666 => 'Consórcio Público da Região PoliNorte',
    672 => 'Conselho Regional de Farmácia do Rio Grande do Sul',
    673 => 'Serviço Autônomo de Agua e Esgoto - SAAE Ibiraçu/ES',
    674 => 'Coordenação de Aperfeiçoamento de Pessoal de Nível',
    677 => 'Secretaria Municipal de Saúde de Campina Grande',
    678 => 'EDUARDO JOSÉ SAGRILLO',
    685 => 'Julio César Pereira de Araújo Filho',
    702 => 'Ediene Bárbara Alves de Siqueira'
  }
  
  puts "Corrigindo #{corrections.size} usuários..."
  
  corrected = 0
  
  corrections.each do |id, correct_name|
    user = User.find_by(id: id)
    
    if user
      old_name = user.name
      user.name = correct_name
      
      if user.save(validate: false)
        puts "✓ ID #{id}: '#{old_name}' → '#{correct_name}'"
        corrected += 1
      else
        puts "✗ ID #{id}: Erro ao salvar"
      end
    else
      puts "⚠ ID #{id}: Usuário não encontrado"
    end
  end
  
  puts "\n✅ Total corrigido: #{corrected} usuários"
end
