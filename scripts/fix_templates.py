#!/usr/bin/env python3
"""
Script para inserir placeholders nos templates DOCX de fatura.
Substitui textos fixos por placeholders que o sistema Rails reconhece.

Placeholders que já existem e funcionam:
  DATADOCUMENTO, DATAVENCIMENTO, NOMECLIENTE, CENTRODECUSTO, CNPJCLIENTE,
  ENDERECOCLIENTE, CIDADECLIENTE, ESTADOCLIENTE, TELEFONECLIENTE, EMAILCLIENTE,
  VALORTOTAL, VALORBRUTO, DISCOUNT, VALORDESCONTO, DESCONTOIR,
  INICIOFATURA, FIMFATURA, 01DATA, 01DESCRICAO, 01VALOR, 01NOTA, 01IR, 01FORNECEDOR, 01CNPJ...

Placeholders NOVOS que precisam ser inseridos no template:
  NOSSONUMERO     - no campo "Nosso número" (vazio atualmente)
  CONTABANCARIA   - substituir "Banco Itaú AG: 8493 C/C: 99569-3" 
  PERCENTUALDESCONTO - substituir "40,12 %" fixo
  NUMEROCONTRATO  - no campo "Número do contrato / Processo" (vazio atualmente)
  RETENCAOESFERA  - adicionar junto às retenções
"""

import os
import sys
import zipfile
import shutil
import io
import re
import glob

def fix_template_xml(xml_content):
    """Aplica todas as substituições de placeholders no XML do template."""
    
    replacements_made = []
    
    # 1. NOSSONUMERO: O campo "Nosso número" tem uma célula vazia após o label.
    #    Inserir NOSSONUMERO no parágrafo vazio que segue "Nosso número"
    #    Pattern: depois de "Nosso número </w:t>...</w:p>" há um <w:p ...></w:p> vazio com jc right
    pattern_nosso = r'(Nosso número </w:t></w:r></w:p><w:p [^>]*><w:pPr><w:tabs><w:tab w:val="center" w:pos="2508"/></w:tabs><w:jc w:val="right"/></w:pPr>)(</w:p>)'
    if re.search(pattern_nosso, xml_content):
        xml_content = re.sub(
            pattern_nosso,
            r'\1<w:r><w:t>NOSSONUMERO</w:t></w:r>\2',
            xml_content
        )
        replacements_made.append('NOSSONUMERO')
    
    # 2. CONTABANCARIA: Substituir o bloco fixo "Banco Itaú ... C/C: 99569-3" 
    #    por um único run com CONTABANCARIA
    #    O template tem: "Banco Itaú " em um parágrafo, "AG: 8493 " em outro, "C/C: 99569-3" em outro
    #    Vamos substituir todo o bloco de 3 parágrafos por um só com CONTABANCARIA
    
    # Abordagem: substituir o texto "Banco Itaú " por "CONTABANCARIA" e remover as linhas AG e CC
    if 'Banco It' in xml_content:
        # Substituir "Banco Itaú " pelo placeholder
        xml_content = xml_content.replace(
            '>Banco Itaú </w:t>',
            '>CONTABANCARIA</w:t>'
        )
        # Remover os parágrafos de AG e C/C que ficam logo abaixo
        # AG: 8493 
        xml_content = re.sub(
            r'<w:p [^>]*><w:pPr><w:pStyle w:val="Default"/><w:rPr><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:pPr><w:r><w:rPr><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr><w:t[^>]*>AG: 8493 </w:t></w:r></w:p>',
            '',
            xml_content
        )
        # C/C: 99569-3
        xml_content = re.sub(
            r'<w:p [^>]*><w:pPr><w:tabs><w:tab w:val="center" w:pos="2508"/></w:tabs></w:pPr><w:r><w:t>C/C: 99569-3</w:t></w:r></w:p>',
            '',
            xml_content
        )
        replacements_made.append('CONTABANCARIA')
    
    # 3. PERCENTUALDESCONTO: Substituir "Preços já com descontos aplicados de 40,12 %"
    #    por "Preços já com descontos aplicados de PERCENTUALDESCONTO"
    if 'descontos aplicados de 40,12 %' in xml_content:
        xml_content = xml_content.replace(
            'descontos aplicados de 40,12 %',
            'descontos aplicados de PERCENTUALDESCONTO'
        )
        replacements_made.append('PERCENTUALDESCONTO')
    elif 'descontos aplicados de' in xml_content:
        # Variação: capturar qualquer porcentagem fixa
        xml_content = re.sub(
            r'descontos aplicados de [0-9,.]+ ?%',
            'descontos aplicados de PERCENTUALDESCONTO',
            xml_content
        )
        replacements_made.append('PERCENTUALDESCONTO (regex)')
    
    # 4. NUMEROCONTRATO: O campo "Número do contrato / Processo" tem célula vazia abaixo.
    #    Encontrar o parágrafo vazio na célula abaixo do header e inserir placeholder
    pattern_contrato = r'(mero do contrato </w:t></w:r><w:r[^>]*><w:rPr><w:b/><w:bCs/></w:rPr><w:t>/ Processo</w:t></w:r></w:p></w:tc></w:tr><w:tr [^>]*><w:tc><w:tcPr><w:tcW [^/]*/></w:tcPr><w:p [^>]*><w:pPr>)'
    match = re.search(pattern_contrato, xml_content)
    if match:
        # Find the empty paragraph after this and insert NUMEROCONTRATO
        end_pos = match.end()
        # Look for the closing </w:p> of the next paragraph
        next_close = xml_content.find('</w:p>', end_pos)
        if next_close > 0:
            # Insert NUMEROCONTRATO run before </w:p>
            xml_content = xml_content[:next_close] + '<w:r><w:t>NUMEROCONTRATO</w:t></w:r>' + xml_content[next_close:]
            replacements_made.append('NUMEROCONTRATO')
    
    # 5. RETENCAOESFERA: Adicionar após a linha de RETENÇÕES no sumário financeiro
    #    O template tem "RETENÇÕES" como label. Precisamos adicionar o valor.
    if 'RETEN' in xml_content and 'RETENCAOESFERA' not in xml_content:
        # Procurar a célula após "RETENÇÕES" e inserir o placeholder na célula de valor
        pattern_ret = r'(RETENÇÕES</w:t></w:r></w:p></w:tc><w:tc><w:tcPr><w:tcW [^/]*/></w:tcPr><w:p [^>]*>)'
        match_ret = re.search(pattern_ret, xml_content)
        if match_ret:
            end_pos = match_ret.end()
            next_close = xml_content.find('</w:p>', end_pos)
            if next_close > 0:
                xml_content = xml_content[:next_close] + '<w:r><w:rPr><w:b/><w:bCs/></w:rPr><w:t>RETENCAOESFERA</w:t></w:r>' + xml_content[next_close:]
                replacements_made.append('RETENCAOESFERA')
    
    # 6. ESFERACLIENTE: Não existe campo no template original, vamos adicionar na seção 
    #    "Informações importantes" junto com o período
    #    "Período da fatura INICIOFATURA a FIMFATURA" -> adicionar "Esfera: ESFERACLIENTE" 
    if 'ESFERACLIENTE' not in xml_content and 'INICIOFATURA' in xml_content:
        # Adicionar no texto de período: "Período da fatura INICIOFATURA a FIMFATURA"
        # Não vamos alterar - a esfera já é usada para cálculo, não precisa estar no documento necessariamente
        replacements_made.append('ESFERACLIENTE (usado apenas para cálculo, não no template)')
    
    return xml_content, replacements_made


def process_docx(filepath):
    """Processa um arquivo .docx e insere placeholders."""
    print(f"\nProcessando: {os.path.basename(filepath)}")
    
    # Lê o conteúdo do ZIP em memória
    entries = {}
    with zipfile.ZipFile(filepath, 'r') as zf:
        for entry in zf.namelist():
            entries[entry] = zf.read(entry)
    
    # Processa o document.xml
    doc_xml = entries.get('word/document.xml')
    if not doc_xml:
        print("  ERRO: word/document.xml não encontrado!")
        return False
    
    xml_str = doc_xml.decode('utf-8')
    xml_modified, replacements = fix_template_xml(xml_str)
    
    if not replacements:
        print("  Nenhuma substituição necessária (já tem placeholders ou template diferente)")
        return False
    
    for r in replacements:
        print(f"  + {r}")
    
    entries['word/document.xml'] = xml_modified.encode('utf-8')
    
    # Faz backup do original
    backup_path = filepath + '.bak'
    if not os.path.exists(backup_path):
        shutil.copy2(filepath, backup_path)
        print(f"  Backup: {os.path.basename(backup_path)}")
    
    # Reescreve o arquivo
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, 'w', zipfile.ZIP_DEFLATED) as zf:
        for name, data in entries.items():
            zf.writestr(name, data)
    
    with open(filepath, 'wb') as f:
        f.write(buffer.getvalue())
    
    print(f"  Salvo com sucesso!")
    return True


def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    public_dir = os.path.join(base_dir, 'public')
    
    templates = sorted(glob.glob(os.path.join(public_dir, 'fatura_[0-9]*.docx')))
    
    if not templates:
        print("ERRO: Nenhum template fatura_*.docx encontrado em public/")
        sys.exit(1)
    
    print(f"Encontrados {len(templates)} templates")
    
    modified = 0
    for t in templates:
        if process_docx(t):
            modified += 1
    
    print(f"\n{'='*50}")
    print(f"Templates modificados: {modified}/{len(templates)}")
    
    if modified > 0:
        print("\nLembre-se de copiar os templates para production/public/ também!")
        print("  cp public/fatura_*.docx production/public/")


if __name__ == '__main__':
    main()
