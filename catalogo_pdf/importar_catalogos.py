# importar_catalogos.py — Pipeline completa de importacao de catalogos PDF -> MySQL
# 
# Modos de uso:
#   python importar_catalogos.py                              → importa todos os PDFs conhecidos
#   python importar_catalogos.py --auto                       → detecta e importa TODOS os PDFs da pasta
#   python importar_catalogos.py --arquivo X.pdf --fornecedor NOME  → importa um PDF específico
#   python importar_catalogos.py --arquivo X.pdf --fornecedor NOME --db-host H --db-port P --db-name D --db-user U --db-pass S
#
# IMPORTANTE: Rode diagnostico.py ANTES para validar a estrutura dos PDFs
#             Rode criar_tabela.py ANTES para criar a tabela no banco

import pdfplumber
import pandas as pd
import pymysql
import pymysql.cursors
import re
import os
import sys
import json
import hashlib
import argparse
import glob
from tqdm import tqdm
from datetime import datetime

# ─────────────────────────────────────────────
# CONFIGURACAO — ajuste com seus dados
# ─────────────────────────────────────────────
DB_CONFIG = {
    "host": "127.0.0.1",
    "port": 3306,
    "database": "sistema_insta_solutions_development",
    "user": "root",
    "password": "rot123"
}

CATALOGOS = [
    {"arquivo": "pdf controil-bra.pdf",  "fornecedor": "CONTROIL"},
    {"arquivo": "pdf lonaflex-bra.pdf",  "fornecedor": "LONAFLEX"},
    {"arquivo": "pdf_frasle-bra.pdf",    "fornecedor": "FRASLE"},
    {"arquivo": "pdf fremax-bra.pdf",    "fornecedor": "FREMAX"},
    {"arquivo": "pdf nakata-bra.pdf",    "fornecedor": "NAKATA"},
]

BATCH_SIZE = 100        # paginas por lote antes de commitar no banco
PAGINA_INICIO = 3       # pular capa + indice (comeca nas aplicacoes)

# ─────────────────────────────────────────────
# MARCAS CONHECIDAS (header de secao nos PDFs)
# ─────────────────────────────────────────────
MARCAS_CONHECIDAS = {
    "AGRALE", "ALFA ROMEO", "ASIA MOTORS", "AUDI", "BMW", "CALOI", "CASE",
    "CHANGAN", "CHERY", "CHEVROLET", "CHRYSLER", "CITROEN", "DAF", "DAELIM",
    "DAEWOO", "DAFRA", "DODGE", "EFFA MOTORS", "FIAT", "FIAT ALLIS", "FNM",
    "FORD", "FOTON", "GAS GAS", "GMC", "GURGEL", "HAFEI", "HONDA", "HUSQVARNA",
    "HYUNDAI", "INTERNATIONAL", "IVECO", "JAC", "JAGUAR", "JEEP", "JINBEI",
    "KIA", "KTM", "LADA", "LAND ROVER", "LEXUS", "LIFAN", "MAHINDRA", "MAN",
    "MASSEY FERGUSON", "MAZDA", "MERCEDES BENZ", "MERCEDES-BENZ", "MINI",
    "MITSUBISHI", "NEW HOLLAND", "NISSAN", "PEUGEOT", "PIAGGIO", "PORSCHE",
    "PUMA", "RAM", "RENAULT", "SCANIA", "SEAT", "SHINERAY", "SINOTRUK",
    "SMART", "SSANGYONG", "SUBARU", "SUNDOWN", "SUZUKI", "TESLA", "TOYOTA",
    "TROLLER", "VALTRA", "VOLARE", "VOLKSWAGEN", "VOLVO", "YAMAHA", "YANMAR",
    "ACURA", "BYD", "CADILLAC", "DAIHATSU", "FERRARI", "GWM",
    "HUMMER", "ISUZU", "LINCOLN", "CROSS LANDER", "KENWORTH", "JOHN DEERE",
    "KAWASAKI", "KASINSKI", "INDIAN", "TRIUMPH"
}


# ─────────────────────────────────────────────
# PARSER DE ANO  ex: "1985/1989" -> (1985, 1989)
# ─────────────────────────────────────────────
def parse_ano(ano_str):
    if not ano_str:
        return None, None
    ano_str = str(ano_str).strip()
    m = re.match(r"(\d{4})[/\-](\d{4})", ano_str)
    if m:
        return int(m.group(1)), int(m.group(2))
    m = re.match(r"(\d{4})", ano_str)
    if m:
        return int(m.group(1)), None
    return None, None


# ─────────────────────────────────────────────
# DETECTA HEADER DE MARCA
# ─────────────────────────────────────────────
def detectar_marca(texto):
    if not texto:
        return None
    t = str(texto).strip().upper()
    if t in MARCAS_CONHECIDAS:
        return t
    return None


# ─────────────────────────────────────────────
# EXTRAI REGISTROS DE UMA PAGINA
# ─────────────────────────────────────────────
def extrair_pagina(pagina, num_pagina, marca_atual, contexto):
    """
    contexto = dict com {veiculo, modelo, motor, ano} da ultima linha valida
    Retorna: (lista_registros, marca_atual_atualizada, contexto_atualizado)
    """
    registros = []

    # Tenta extrair tabelas com linhas primeiro
    tabelas = pagina.extract_tables({
        "vertical_strategy": "lines",
        "horizontal_strategy": "lines",
    })

    if not tabelas:
        # Fallback: tenta sem bordas (algumas paginas usam espaco)
        tabelas = pagina.extract_tables()

    if not tabelas:
        return registros, marca_atual, contexto

    for tabela in tabelas:
        for linha in tabela:
            if not linha or all(c is None or str(c).strip() == "" for c in linha):
                continue

            # Limpa os valores
            cols = [str(c).strip() if c else "" for c in linha]

            # Garante pelo menos 7 colunas
            while len(cols) < 7:
                cols.append("")

            col0, col1, col2, col3, col4, col5, col6 = (
                cols[0], cols[1], cols[2], cols[3], cols[4], cols[5], cols[6]
            )

            # Detecta header de marca (ex: "AGRALE", "VOLKSWAGEN")
            marca_detectada = detectar_marca(col0)
            if marca_detectada:
                marca_atual = marca_detectada
                # Reset contexto ao mudar de marca
                contexto = {"veiculo": "", "modelo": "", "motor": "", "ano": ""}
                continue

            # Ignora linha de cabecalho da tabela
            if col0.lower() in ("veiculo", "veículo", "vehicle", "marca"):
                continue

            # Forward-fill: usa valor da linha anterior se celula vazia
            if col0:
                contexto["veiculo"] = col0
            if col1:
                contexto["modelo"] = col1
            if col2:
                contexto["motor"] = col2
            if col3:
                contexto["ano"] = col3

            # Produto e grupo sao obrigatorios — sem eles ignora
            if not col4 and not col5:
                continue

            ano_inicio, ano_fim = parse_ano(contexto["ano"])

            registro = {
                "marca": marca_atual or "",
                "veiculo": contexto["veiculo"],
                "modelo": contexto["modelo"],
                "motor": contexto["motor"],
                "ano_inicio": ano_inicio,
                "ano_fim": ano_fim,
                "grupo_produto": col4,
                "produto": col5,
                "observacao": col6,
                "pagina_origem": num_pagina
            }
            registros.append(registro)

    return registros, marca_atual, contexto


# ─────────────────────────────────────────────
# INSERE LOTE NO MYSQL
# ─────────────────────────────────────────────
def inserir_lote(conn, registros, fornecedor, arquivo_origem=''):
    if not registros:
        return 0, 0

    cursor = conn.cursor()
    inseridos = 0
    duplicatas = 0

    sql = """
        INSERT INTO catalogo_pecas 
            (fornecedor, marca, veiculo, modelo, motor, ano_inicio, ano_fim,
             grupo_produto, produto, observacao, pagina_origem, arquivo_origem,
             created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
        ON DUPLICATE KEY UPDATE id=id
    """

    for r in registros:
        try:
            cursor.execute(sql, (
                fornecedor,
                r["marca"][:100],
                r["veiculo"][:150],
                r["modelo"][:150],
                r["motor"][:100],
                r["ano_inicio"],
                r["ano_fim"],
                r["grupo_produto"][:200],
                r["produto"][:150],
                r["observacao"][:300],
                r["pagina_origem"],
                arquivo_origem[:255]
            ))
            if cursor.rowcount > 0:
                inseridos += 1
            else:
                duplicatas += 1
        except Exception as e:
            print(f"  Aviso na linha: {r.get('produto', '?')} -> {e}")
            continue

    conn.commit()
    cursor.close()
    return inseridos, duplicatas


# ─────────────────────────────────────────────
# PROCESSA UM PDF COMPLETO
# ─────────────────────────────────────────────
def processar_catalogo(caminho_pdf, fornecedor, conn, arquivo_origem=''):
    print(f"\n{'='*60}")
    print(f"Iniciando: {fornecedor}")
    print(f"Arquivo: {caminho_pdf}")
    print(f"{'='*60}")

    if not os.path.exists(caminho_pdf):
        print(f"Arquivo nao encontrado: {caminho_pdf}")
        return 0

    erros = []
    total_inseridos = 0
    total_duplicatas = 0
    lote = []
    marca_atual = ""
    contexto = {"veiculo": "", "modelo": "", "motor": "", "ano": ""}
    ja_encontrou_dados = False  # flag para nao parar no indice

    inicio = datetime.now()

    with pdfplumber.open(caminho_pdf) as pdf:
        total_paginas = len(pdf.pages)
        paginas_aplicacoes = list(range(PAGINA_INICIO - 1, total_paginas))

        print(f"Total de paginas: {total_paginas}")
        print(f"Processando a partir da pagina {PAGINA_INICIO}...")

        for i in tqdm(paginas_aplicacoes, desc=f"{fornecedor}"):
            pagina = pdf.pages[i]
            num_pagina = i + 1

            # Para quando chega na secao de Referencias Cruzadas ou Imagens
            # MAS so para se ja encontrou dados (evita parar no indice)
            texto_pagina = pagina.extract_text() or ""
            if ja_encontrou_dados and any(s in texto_pagina[:200] for s in [
                "Referências Cruzadas", "REFERÊNCIAS CRUZADAS",
                "References", "Imagens", "Desenhos", "Especificações Técnicas"
            ]):
                if "Veículo" not in texto_pagina and "Aplicações" not in texto_pagina:
                    print(f"\n  Secao de aplicacoes encerrada na pagina {num_pagina}")
                    break

            try:
                registros, marca_atual, contexto = extrair_pagina(
                    pagina, num_pagina, marca_atual, contexto
                )
                if registros:
                    ja_encontrou_dados = True
                lote.extend(registros)

            except Exception as e:
                erros.append({"pagina": num_pagina, "erro": str(e)})
                continue

            # Commita a cada BATCH_SIZE paginas (~1000 registros)
            if len(lote) >= BATCH_SIZE * 10:
                ins, dup = inserir_lote(conn, lote, fornecedor, arquivo_origem)
                total_inseridos += ins
                total_duplicatas += dup
                lote = []
                print(f"  Salvo ate pagina {num_pagina} | +{ins} inseridos")

        # Insere o restante
        if lote:
            ins, dup = inserir_lote(conn, lote, fornecedor, arquivo_origem)
            total_inseridos += ins
            total_duplicatas += dup

    tempo = (datetime.now() - inicio).seconds
    print(f"\n{fornecedor} concluido em {tempo}s")
    print(f"   Inseridos: {total_inseridos:,}")
    print(f"   Duplicatas ignoradas: {total_duplicatas:,}")
    print(f"   Erros: {len(erros)}")

    if erros:
        log_file = f"erros_{fornecedor.lower()}.json"
        with open(log_file, "w", encoding="utf-8") as f:
            json.dump(erros, f, ensure_ascii=False, indent=2)
        print(f"   Erros salvos em: {log_file}")

    return total_inseridos


# ─────────────────────────────────────────────
# DETECCAO AUTOMATICA DE FORNECEDOR PELO NOME DO ARQUIVO
# ─────────────────────────────────────────────
FORNECEDORES_CONHECIDOS = {
    "controil": "CONTROIL",
    "lonaflex": "LONAFLEX",
    "frasle": "FRASLE",
    "fras-le": "FRASLE",
    "fremax": "FREMAX",
    "nakata": "NAKATA",
    "mahle": "MAHLE",
    "gates": "GATES",
    "monroe": "MONROE",
    "trw": "TRW",
    "bosch": "BOSCH",
    "denso": "DENSO",
    "sachs": "SACHS",
    "wega": "WEGA",
    "mann": "MANN",
    "skf": "SKF",
    "cofap": "COFAP",
    "dayco": "DAYCO",
    "valeo": "VALEO",
    "nsk": "NSK",
    "sabó": "SABO",
    "sabo": "SABO",
    "urba": "URBA",
    "hipper": "HIPPER FREIOS",
}

def detectar_fornecedor(filename):
    """Detecta o fornecedor pelo nome do arquivo PDF"""
    nome = filename.lower()
    for chave, fornecedor in FORNECEDORES_CONHECIDOS.items():
        if chave in nome:
            return fornecedor
    # Fallback: extrai do nome do arquivo
    nome_limpo = re.sub(r'^pdf[_\s-]*', '', nome)
    nome_limpo = re.sub(r'[-_]bra.*$', '', nome_limpo)
    nome_limpo = re.sub(r'\d+', '', nome_limpo).strip()
    return nome_limpo.upper() if nome_limpo else "DESCONHECIDO"


def criar_tabela_se_nao_existe(conn):
    """Cria a tabela catalogo_pecas se não existir"""
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS catalogo_pecas (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            fornecedor VARCHAR(50) NOT NULL,
            marca VARCHAR(100) DEFAULT '',
            veiculo VARCHAR(150) DEFAULT '',
            modelo VARCHAR(150) DEFAULT '',
            motor VARCHAR(100) DEFAULT '',
            ano_inicio INT DEFAULT NULL,
            ano_fim INT DEFAULT NULL,
            grupo_produto VARCHAR(200) DEFAULT '',
            produto VARCHAR(150) DEFAULT '',
            observacao VARCHAR(300) DEFAULT '',
            pagina_origem INT DEFAULT NULL,
            arquivo_origem VARCHAR(255) DEFAULT '',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY uk_catalogo (fornecedor, marca(50), veiculo(50), modelo(50), motor(50), ano_inicio, ano_fim, grupo_produto(80), produto(80))
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    """)
    
    # Indices
    for idx_sql in [
        "CREATE INDEX idx_catalogo_marca ON catalogo_pecas(marca);",
        "CREATE INDEX idx_catalogo_veiculo ON catalogo_pecas(veiculo, modelo);",
        "CREATE INDEX idx_catalogo_produto ON catalogo_pecas(produto);",
        "CREATE INDEX idx_catalogo_fornecedor ON catalogo_pecas(fornecedor);",
    ]:
        try:
            cursor.execute(idx_sql)
        except:
            pass  # indice ja existe

    conn.commit()
    cursor.close()


# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description='Importa catalogos PDF de pecas para MySQL')
    parser.add_argument('--arquivo', help='Caminho do arquivo PDF para importar')
    parser.add_argument('--fornecedor', help='Nome do fornecedor (ex: NAKATA, FREMAX)')
    parser.add_argument('--auto', action='store_true', help='Detecta e importa todos os PDFs da pasta automaticamente')
    parser.add_argument('--db-host', default=DB_CONFIG['host'], help='Host do MySQL')
    parser.add_argument('--db-port', type=int, default=DB_CONFIG['port'], help='Porta do MySQL')
    parser.add_argument('--db-name', default=DB_CONFIG['database'], help='Nome do banco')
    parser.add_argument('--db-user', default=DB_CONFIG['user'], help='Usuario do MySQL')
    parser.add_argument('--db-pass', default=DB_CONFIG['password'], help='Senha do MySQL')

    args = parser.parse_args()

    pasta = os.path.dirname(os.path.abspath(__file__))
    os.chdir(pasta)

    # Atualiza DB_CONFIG com argumentos da CLI
    # pymysql usa 'db' em vez de 'database'
    db_config = {
        "host": args.db_host,
        "port": args.db_port,
        "db": args.db_name,
        "user": args.db_user,
        "password": args.db_pass,
        "charset": "utf8mb4",
        "autocommit": False
    }

    print("Conectando ao MySQL...")
    try:
        conn = pymysql.connect(**db_config)
        print("Conexao estabelecida!")
    except Exception as e:
        print(f"Erro na conexao: {e}")
        return

    # Cria tabela automaticamente
    criar_tabela_se_nao_existe(conn)

    total_geral = 0

    if args.arquivo and args.fornecedor:
        # Modo: importar um PDF específico
        total = processar_catalogo(args.arquivo, args.fornecedor, conn, args.arquivo)
        total_geral += total

    elif args.auto:
        # Modo: detectar e importar TODOS os PDFs da pasta
        pdfs = glob.glob(os.path.join(pasta, '*.pdf'))
        print(f"\nPDFs encontrados na pasta: {len(pdfs)}")

        for pdf_path in sorted(pdfs):
            filename = os.path.basename(pdf_path)
            fornecedor = detectar_fornecedor(filename)
            print(f"\n  {filename} -> {fornecedor}")
            total = processar_catalogo(pdf_path, fornecedor, conn, filename)
            total_geral += total

    else:
        # Modo: importar lista fixa de PDFs
        for catalogo in CATALOGOS:
            total = processar_catalogo(
                catalogo["arquivo"],
                catalogo["fornecedor"],
                conn,
                catalogo["arquivo"]
            )
            total_geral += total

    conn.close()
    print(f"\n{'='*60}")
    print(f"IMPORTACAO CONCLUIDA")
    print(f"   Total geral inserido: {total_geral:,} registros")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
