import sys
import pymysql

try:
    conn = pymysql.connect(host='127.0.0.1', port=3306, db='sistema_insta_solutions_development', user='root', password='rot123', charset='utf8mb4')
    cur = conn.cursor()

    # Check which tables exist
    cur.execute("SHOW TABLES LIKE 'catalogo_pecas%%'")
    tables = cur.fetchall()
    print("Tables:", [t[0] for t in tables], flush=True)

    for t in tables:
        cur.execute("SELECT COUNT(*) FROM `%s`" % t[0])
        count = cur.fetchone()[0]
        print("  %s: %d records" % (t[0], count), flush=True)

    # Show by fornecedor for the main table
    main_table = 'catalogo_pecas' if ('catalogo_pecas',) in tables else 'catalogo_pecas_dedup'
    cur.execute("SELECT fornecedor, COUNT(*) as c FROM `%s` GROUP BY fornecedor ORDER BY c DESC" % main_table)
    for r in cur.fetchall():
        print("  %-30s %8d" % (r[0], r[1]), flush=True)

    conn.close()
    print("Done.", flush=True)
except Exception as e:
    print("ERROR: %s" % str(e), flush=True)
    sys.exit(1)
