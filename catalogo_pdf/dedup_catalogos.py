"""Remove duplicatas da tabela catalogo_pecas mantendo o registro com menor ID"""
import pymysql

conn = pymysql.connect(host='127.0.0.1', port=3306, db='sistema_insta_solutions_development', 
                       user='root', password='rot123', charset='utf8mb4')
cur = conn.cursor()

print("Contando registros antes...")
cur.execute('SELECT COUNT(*) FROM catalogo_pecas')
antes = cur.fetchone()[0]
print(f"  Registros antes: {antes:,}")

print("\nCriando tabela temporaria com registros unicos...")
cur.execute("SET sql_mode = ''")
cur.execute("""
    CREATE TABLE catalogo_pecas_dedup AS
    SELECT MIN(id) as id, fornecedor, marca, veiculo, modelo, motor, 
           ano_inicio, ano_fim, grupo_produto, produto, 
           MAX(observacao) as observacao,
           MAX(pagina_origem) as pagina_origem, 
           MAX(arquivo_origem) as arquivo_origem, 
           MIN(created_at) as created_at, MAX(updated_at) as updated_at
    FROM catalogo_pecas
    GROUP BY fornecedor, COALESCE(marca,''), COALESCE(veiculo,''), COALESCE(modelo,''), 
             COALESCE(motor,''), COALESCE(ano_inicio,0), COALESCE(ano_fim,0),
             COALESCE(grupo_produto,''), COALESCE(produto,'')
""")
conn.commit()

cur.execute('SELECT COUNT(*) FROM catalogo_pecas_dedup')
unicos = cur.fetchone()[0]
print(f"  Registros unicos: {unicos:,}")
print(f"  Duplicatas: {antes - unicos:,}")

print("\nSubstituindo tabela...")
cur.execute("DROP TABLE catalogo_pecas")
cur.execute("RENAME TABLE catalogo_pecas_dedup TO catalogo_pecas")

print("Recriando indices...")
for idx in [
    "ALTER TABLE catalogo_pecas ADD PRIMARY KEY (id)",
    "ALTER TABLE catalogo_pecas MODIFY id BIGINT AUTO_INCREMENT",
    "CREATE INDEX idx_catalogo_marca ON catalogo_pecas(marca)",
    "CREATE INDEX idx_catalogo_veiculo ON catalogo_pecas(veiculo, modelo)",
    "CREATE INDEX idx_catalogo_produto ON catalogo_pecas(produto)",
    "CREATE INDEX idx_catalogo_fornecedor ON catalogo_pecas(fornecedor)",
]:
    try:
        cur.execute(idx)
    except Exception as e:
        print(f"  Aviso: {e}")

conn.commit()

print("\nResultado final:")
cur.execute('SELECT fornecedor, COUNT(*) as c FROM catalogo_pecas GROUP BY fornecedor ORDER BY c DESC')
for r in cur.fetchall():
    print(f"  {r[0]:30s} {r[1]:>8d}")
cur.execute('SELECT COUNT(*) FROM catalogo_pecas')
print(f"\n  TOTAL FINAL: {cur.fetchone()[0]:,}")

conn.close()
print("\nConcluido!")
