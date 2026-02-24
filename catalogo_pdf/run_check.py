import pymysql, sys, traceback
try:
    conn = pymysql.connect(host='127.0.0.1', port=3306, db='sistema_insta_solutions_development', user='root', password='rot123', charset='utf8mb4', connect_timeout=5)
    cur = conn.cursor()
    
    cur.execute("SHOW TABLES LIKE 'catalogo_pecas%%'")
    tables = [t[0] for t in cur.fetchall()]
    print("Tables found: " + str(tables), flush=True)
    
    cur.execute('SELECT COUNT(*) FROM catalogo_pecas')
    total = cur.fetchone()[0]
    print("TOTAL records: " + str(total), flush=True)
    
    cur.execute('SELECT fornecedor, COUNT(*) as c FROM catalogo_pecas GROUP BY fornecedor ORDER BY c DESC')
    rows = cur.fetchall()
    print("Number of groups: " + str(len(rows)), flush=True)
    for r in rows:
        forn = str(r[0]) if r[0] else "(NULL)"
        cnt = r[1]
        print("  " + forn + ": " + str(cnt), flush=True)
    
    conn.close()
    print("Done.", flush=True)
except Exception as e:
    print("ERROR: " + str(e), flush=True)
    traceback.print_exc()
    sys.exit(1)
