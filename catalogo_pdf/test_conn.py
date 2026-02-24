import sys
print("Script started", flush=True)
try:
    import pymysql
    print("pymysql imported OK", flush=True)
    conn = pymysql.connect(
        host='127.0.0.1', port=3306,
        db='sistema_insta_solutions_development',
        user='root', password='rot123',
        charset='utf8mb4',
        autocommit=True,
        connect_timeout=10
    )
    print("Connected OK", flush=True)
    cur = conn.cursor()
    cur.execute("SHOW TABLES LIKE 'catalogo_pecas%'")
    tables = [t[0] for t in cur.fetchall()]
    print(f"Tables: {tables}", flush=True)
    for t in tables:
        cur.execute(f"SELECT COUNT(*) FROM `{t}`")
        print(f"  {t}: {cur.fetchone()[0]} records", flush=True)
    conn.close()
    print("Done", flush=True)
except Exception as e:
    print(f"ERROR: {type(e).__name__}: {e}", flush=True)
    sys.exit(1)
