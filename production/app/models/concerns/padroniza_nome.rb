# Concern para padronizar nomes de peças e serviços
# Aplica Title Case inteligente para o contexto automotivo brasileiro
# Ex: "FILTRO DE OLEO" → "Filtro de Óleo"
#     "amortecedor dianteiro" → "Amortecedor Dianteiro"
#     "BOMBA D'AGUA" → "Bomba D'Água"
#
# Usado em: Service, ProviderServiceTemp, OrderServiceProposalItem
module PadronizaNome
  extend ActiveSupport::Concern

  # Preposições e artigos que ficam minúsculos (exceto quando é a primeira palavra)
  # NÃO incluir 'ar' aqui — pode ser sigla (AR condicionado)
  PALAVRAS_MENORES = %w[
    de do da dos das em no na nos nas ao aos com por para
    e ou o a os as um uma uns umas
  ].freeze

  # Palavras técnicas que devem manter formato específico
  PALAVRAS_ESPECIAIS = {
    "abs" => "ABS", "gnv" => "GNV", "glp" => "GLP",
    "led" => "LED", "bi" => "Bi", "atf" => "ATF",
    "cv" => "CV", "hp" => "HP", "rpm" => "RPM",
    "ac" => "AC", "pvc" => "PVC", "egr" => "EGR",
    "suv" => "SUV", "4x4" => "4x4", "4x2" => "4x2",
    "ug" => "UG", "gl" => "GL", "gls" => "GLS",
    "nkf" => "NKF", "pd" => "PD", "bd" => "BD",
  }.freeze

  # Acentos comuns em peças automotivas (normaliza termos conhecidos)
  ACENTOS_COMUNS = {
    "oleo" => "Óleo", "agua" => "Água", "dagua" => "D'Água",
    "d'agua" => "D'Água", "cambio" => "Câmbio", "freio" => "Freio",
    "combustivel" => "Combustível", "cabine" => "Cabine",
    "hidraulico" => "Hidráulico", "hidraulica" => "Hidráulica",
    "eletrico" => "Elétrico", "eletrica" => "Elétrica",
    "mecanico" => "Mecânico", "mecanica" => "Mecânica",
    "pneumatico" => "Pneumático", "pneumatica" => "Pneumática",
    "valvula" => "Válvula", "lampada" => "Lâmpada",
    "parabola" => "Parábola", "cilindro" => "Cilindro",
    "primario" => "Primário", "secundario" => "Secundário",
    "traseiro" => "Traseiro", "traseira" => "Traseira",
    "dianteiro" => "Dianteiro", "dianteira" => "Dianteira",
    "inferior" => "Inferior", "superior" => "Superior",
    "direçao" => "Direção", "direcao" => "Direção",
    "suspensao" => "Suspensão", "transmissao" => "Transmissão",
    "embreagem" => "Embreagem", "igniçao" => "Ignição",
    "ignicao" => "Ignição", "ventilaçao" => "Ventilação",
    "ventilacao" => "Ventilação", "refrigeraçao" => "Refrigeração",
    "refrigeracao" => "Refrigeração", "amortecedor" => "Amortecedor",
    "escapamento" => "Escapamento", "alternador" => "Alternador",
    "catalisador" => "Catalisador", "compressor" => "Compressor",
    "radiador" => "Radiador", "reservatorio" => "Reservatório",
    "resistencia" => "Resistência", "atuaçao" => "Atuação",
    "rolamento" => "Rolamento", "retentor" => "Retentor",
    "mangueira" => "Mangueira", "correia" => "Correia",
    "parafuso" => "Parafuso", "abraçadeira" => "Abraçadeira",
    "abracadeira" => "Abraçadeira", "coxim" => "Coxim",
    "cruzeta" => "Cruzeta", "homocinética" => "Homocinética",
    "homocinetica" => "Homocinética", "semieixo" => "Semieixo",
    "biela" => "Biela", "bieleta" => "Bieleta",
    "terminal" => "Terminal", "pivô" => "Pivô", "pivo" => "Pivô",
    "revisao" => "Revisão", "preventiva" => "Preventiva",
    "corretiva" => "Corretiva",
    "diagnostico" => "Diagnóstico", "alinhamento" => "Alinhamento",
    "balanceamento" => "Balanceamento", "geometria" => "Geometria",
    "calibragem" => "Calibragem", "lubrificaçao" => "Lubrificação",
    "lubrificacao" => "Lubrificação",
    "termostatica" => "Termostática", "termostatico" => "Termostático",
    "estabilizadora" => "Estabilizadora", "estabilizador" => "Estabilizador",
    "bucha" => "Bucha", "polia" => "Polia", "tensor" => "Tensor",
    "junta" => "Junta", "gaxeta" => "Gaxeta", "vedacao" => "Vedação",
    "carter" => "Cárter", "protetor" => "Protetor",
    "ventilador" => "Ventilador", "condensador" => "Condensador",
    "evaporador" => "Evaporador",
    "modulo" => "Módulo", "bobina" => "Bobina", "vela" => "Vela",
    "bateria" => "Bateria", "fusivel" => "Fusível",
    "parachoque" => "Para-choque", "paralama" => "Para-lama",
    "parabrisa" => "Para-brisa", "limpador" => "Limpador",
    "palheta" => "Palheta", "lanterna" => "Lanterna",
    "farol" => "Farol", "retrovisor" => "Retrovisor",
    "sapata" => "Sapata", "tambor" => "Tambor", "pinça" => "Pinça",
    "pinca" => "Pinça", "cubo" => "Cubo",
    "borracha" => "Borracha", "calco" => "Calço",
    "pastilha" => "Pastilha", "disco" => "Disco",
    "bomba" => "Bomba", "filtro" => "Filtro", "troca" => "Troca",
    "instalacao" => "Instalação", "reparo" => "Reparo",
    "kit" => "Kit", "jogo" => "Jogo", "par" => "Par",
    "montagem" => "Montagem", "desmontagem" => "Desmontagem",
    "guincho" => "Guincho", "lavagem" => "Lavagem",
    "funilaria" => "Funilaria", "pintura" => "Pintura",
    "eletronico" => "Eletrônico", "eletronica" => "Eletrônica",
    "diferencial" => "Diferencial", "caixa" => "Caixa",
    "tracao" => "Tração",
    "engrenagem" => "Engrenagem", "pneu" => "Pneu",
    "coifa" => "Coifa", "flexivel" => "Flexível",
    "mao" => "Mão", "servico" => "Serviço", "peca" => "Peça",
  }.freeze

  included do
    # Subclasses definem qual campo padronizar via class method
    # Service → :name, OrderServiceProposalItem → :service_name, ProviderServiceTemp → :name
  end

  # Correções de encoding corrompido (ó/? no lugar de acentos corretos)
  # Substrings mais longas primeiro para evitar substituições parciais
  CORRECOES_ENCODING = [
    # Quadruplo ?? = ção (ç+ã)
    ["????o", "ção"], ["????O", "ÇÃO"],
    # Duplo ?? = caractere acentuado (contextual - tratar por palavra)

    # ó incorreto → acento correto (substrings automotivas comuns)
    ["Cabeóote", "Cabeçote"], ["cabeóote", "cabeçote"],
    ["Lómpada", "Lâmpada"], ["lómpada", "lâmpada"],
    ["Cómbio", "Câmbio"], ["cómbio", "câmbio"],
    ["Cómera", "Câmera"], ["cómera", "câmera"],
    ["Sintótico", "Sintético"], ["sintótico", "sintético"],
    ["Termostótica", "Termostática"], ["termostótica", "termostática"],
    ["Hidróulico", "Hidráulico"], ["hidróulico", "hidráulico"],
    ["Pneumótico", "Pneumático"], ["pneumótico", "pneumático"],
    ["Resistóncia", "Resistência"], ["resistóncia", "resistência"],
    ["Combustóvel", "Combustível"], ["combustóvel", "combustível"],
    ["Flexóvel", "Flexível"], ["flexóvel", "flexível"],
    ["Lóquido", "Líquido"], ["lóquido", "líquido"],
    ["Luminória", "Luminária"], ["luminória", "luminária"],
    ["Odómetro", "Odômetro"], ["odómetro", "odômetro"],
    ["Primório", "Primário"], ["primório", "primário"],
    ["Secundório", "Secundário"], ["secundório", "secundário"],
    ["Abraóadeira", "Abraçadeira"], ["abraóadeira", "abraçadeira"],
    ["Seguranóa", "Segurança"], ["seguranóa", "segurança"],
    ["Maóaneta", "Maçaneta"], ["maóaneta", "maçaneta"],
    ["Corredióa", "Corrediça"], ["corredióa", "corrediça"],
    ["Dobradióa", "Dobradiça"], ["dobradióa", "dobradiça"],
    ["Cuóca", "Cuíca"], ["cuóca", "cuíca"],
    ["Reforóo", "Reforço"], ["reforóo", "reforço"],
    ["Presurizaóao", "Pressurização"],
    ["Remoóao", "Remoção"], ["remoóao", "remoção"],
    ["Chapeaóao", "Chapeação"], ["Suspenóao", "Suspensão"],
    ["Ignióao", "Ignição"], ["ignióao", "ignição"],
    # ço → ção (ã perdido)
    ["Recuperaço", "Recuperação"], ["Proteço", "Proteção"],
    ["Injeço", "Injeção"], ["Lubrificaço", "Lubrificação"],
    ["Manutenço", "Manutenção"], ["Verificaço", "Verificação"],
    ["Rotaço", "Rotação"], ["Reprogramaço", "Reprogramação"],
    ["Chapeaço", "Chapeação"], ["Suspenço", "Suspensão"],
    # óo → ão ou ço
    ["Móo", "Mão"], ["Botóo", "Botão"], ["Conexóo", "Conexão"],
    ["Transmissóo", "Transmissão"], ["Admissóo", "Admissão"],
    ["Pressóo", "Pressão"], ["Revisóo", "Revisão"],
    ["Braóo", "Braço"], ["Calóo", "Calço"], ["Aóo", "Aço"],
    # ó → outros acentos
    [" Gós", " Gás"], ["Córter", "Cárter"],
    [" Ró", " Ré"], # Marcha Ré, Camera de Ré
    ["Ógua", "Água"],
    ["Nóvel", "Nível"],
    # ?? simples (duplo question mark = 1 char acentuado)
    ["Servi??o", "Serviço"], ["M??o", "Mão"], ["Bra??o", "Braço"],
    ["Cal??o", "Calço"], ["Bot??o", "Botão"], ["Cabe??ote", "Cabeçote"],
    ["Refor??o", "Reforço"], ["A??o", "Aço"], ["Press??o", "Pressão"],
    ["Abra??adeira", "Abraçadeira"], ["Seguran??a", "Segurança"],
    ["Cu??ca", "Cuíca"], ["C??mbio", "Câmbio"], ["C??mera", "Câmera"],
    ["L??mpada", "Lâmpada"], ["L??quido", "Líquido"], ["G??s", "Gás"],
    ["Lumin??ria", "Luminária"], ["Prim??rio", "Primário"],
    ["Secund??rio", "Secundário"], ["Combust??vel", "Combustível"],
    ["Flex??vel", "Flexível"], ["N??vel", "Nível"],
    ["Transmiss??o", "Transmissão"], ["Admiss??o", "Admissão"],
    ["Revis??o", "Revisão"], ["Conex??o", "Conexão"],
    ["Expans??o", "Expansão"], ["Suspens??o", "Suspensão"],
    ["Termost??tica", "Termostática"], ["Pneum??tico", "Pneumático"],
    ["Hidr??ulico", "Hidráulico"], ["El??tric", "Elétric"],
    ["Sint??tico", "Sintético"], ["C??rter", "Cárter"],
    ["Diagn??stico", "Diagnóstico"], ["Reservat??rio", "Reservatório"],
    ["R??", "Ré"], ["??leo", "Óleo"], ["??gua", "Água"],
    ["Dobradi??a", "Dobradiça"], ["Ma??aneta", "Maçaneta"],
    ["Corredi??a", "Corrediça"], ["Carca??a", "Carcaça"],
    ["Sa??da", "Saída"], ["Piv??", "Pivô"], ["Buj??o", "Bujão"],
    ["Cart??o", "Cartão"], ["Tac??grafo", "Tacógrafo"],
    ["Pe??as", "Peças"], ["Balan??a", "Balança"],
    ["Veda????o", "Vedação"], ["Suspen??ao", "Suspensão"],
    ["V??lvula", "Válvula"], ["Remo??ao", "Remoção"],
    ["Presuriza??ao", "Pressurização"], ["Igni??ao", "Ignição"],
  ].freeze

  class_methods do
    # Corrige encoding corrompido antes da padronização
    # Usa matching case-insensitive para funcionar com ALL CAPS e mixed case
    def corrigir_encoding(nome)
      return nome if nome.blank?
      resultado = nome.to_s.dup
      CORRECOES_ENCODING.each do |errado, correto|
        # Case-insensitive gsub que preserva o correto
        resultado.gsub!(Regexp.new(Regexp.escape(errado), Regexp::IGNORECASE), correto)
      end
      resultado
    end

    # Padroniza um nome para Title Case inteligente
    # Respeita preposições, acentos automotivos e termos técnicos
    def padronizar_nome_peca(nome)
      return nome if nome.blank?

      nome_limpo = corrigir_encoding(nome.to_s.strip.gsub(/\s+/, ' '))
      return nome_limpo if nome_limpo.length <= 2

      palavras = nome_limpo.split(' ')

      resultado = palavras.each_with_index.map do |palavra, idx|
        # Separa prefixo/sufixo de pontuação (parênteses, etc.)
        prefixo = ''
        sufixo = ''
        nucleo = palavra
        if nucleo =~ /\A([(\[{]+)(.*)\z/
          prefixo = $1
          nucleo = $2
        end
        if nucleo =~ /\A(.*?)([)\]},;:!?]+)\z/
          nucleo = $1
          sufixo = $2
        end

        # Processa o núcleo da palavra (sem pontuação)
        palavra_lower = nucleo.downcase
        palavra_sem_acento = I18n.transliterate(palavra_lower) rescue palavra_lower

        # 1. Verifica palavra especial (siglas técnicas)
        resultado_palavra = if nucleo.blank?
          nucleo
        elsif PALAVRAS_ESPECIAIS[palavra_sem_acento]
          PALAVRAS_ESPECIAIS[palavra_sem_acento]

        # 2. Verifica se tem acento comum conhecido
        elsif ACENTOS_COMUNS[palavra_sem_acento]
          ACENTOS_COMUNS[palavra_sem_acento]

        # 3. Preposições/artigos ficam minúsculos (exceto primeira palavra)
        elsif idx > 0 && PALAVRAS_MENORES.include?(palavra_sem_acento)
          palavra_lower

        # 4. Mantém padrões de medida/código (ex: 175/65R14, 15W40)
        elsif nucleo =~ /\d+[\/.]+\d*/ || nucleo =~ /\d+[A-Za-z]+\d*/
          nucleo

        # 4b. Palavras curtas ALL CAPS (<=3 chars) — provavelmente siglas, manter
        elsif nucleo.length <= 3 && nucleo == nucleo.upcase && nucleo =~ /[A-Z]/
          nucleo

        # 5. Palavra já tem acento (o usuário digitou corretamente) - apenas Title Case
        elsif nucleo != I18n.transliterate(nucleo)
          palavra_lower.mb_chars.capitalize.to_s

        # 6. Title case padrão
        else
          palavra_lower.mb_chars.capitalize.to_s
        end

        # Reconstroi com pontuação original
        "#{prefixo}#{resultado_palavra}#{sufixo}"
      end

      resultado.join(' ')
    end
  end
end
