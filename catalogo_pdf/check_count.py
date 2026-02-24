import pymysql, sys
try:
    conn = pymysql.connect(host='127.0.0.1', port=3306, db='sistema_insta_solutions_development', user='root', password='rot123', charset='utf8mb4', connect_timeout=5)
    cur = conn.cursor()
    
    # Check tables
    cur.execute("SHOW TABLES LIKE 'catalogo_pecas%%'")
    tables = [t[0] for t in cur.fetchall()]
    print(f"Tables found: {tables}", flush=True)
    
    if 'catalogo_pecas_dedup' in tables:
        print("WARNING: catalogo_pecas_dedup exists (dedup may be in progress)", flush=True)

    # Check columns
    cur.execute("DESCRIBE catalogo_pecas")
    cols = [r[0] for r in cur.fetchall()]
    print(f"Columns: {cols}", flush=True)
    
    cur.execute('SELECT fornecedor, COUNT(*) as c FROM catalogo_pecas GROUP BY fornecedor ORDER BY c DESC')
    for r in cur.fetchall():
        print(f'{r[0]:30s} {r[1]:>8d}', flush=True)
    cur.execute('SELECT COUNT(*) FROM catalogo_pecas')
    total = cur.fetchone()[0]
    print(f'TOTAL: {total}', flush=True)
    conn.close()
except Exception as e:
    print(f"ERROR: {e}", flush=True)
    sys.exit(1)
