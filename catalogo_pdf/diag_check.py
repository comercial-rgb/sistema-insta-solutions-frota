import pymysql, sys, traceback, os

outfile = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'diag_output.txt')
f = open(outfile, 'w', encoding='utf-8')

def log(msg):
    f.write(msg + '\n')
    f.flush()

try:
    log("Step 1: Connecting...")
    conn = pymysql.connect(host='127.0.0.1', port=3306, db='sistema_insta_solutions_development', user='root', password='rot123', charset='utf8mb4', connect_timeout=5)
    cur = conn.cursor()
    log("Step 2: Connected OK")
    
    cur.execute("SHOW TABLES LIKE 'catalogo_pecas%%'")
    tables = [t[0] for t in cur.fetchall()]
    log("Step 3: Tables = " + str(tables))
    
    log("Step 4: Running COUNT...")
    cur.execute('SELECT COUNT(*) FROM catalogo_pecas')
    total = cur.fetchone()[0]
    log("Step 5: TOTAL = " + str(total))
    
    log("Step 6: Running GROUP BY...")
    cur.execute('SELECT fornecedor, COUNT(*) as c FROM catalogo_pecas GROUP BY fornecedor ORDER BY c DESC')
    rows = cur.fetchall()
    log("Step 7: Groups = " + str(len(rows)))
    
    for r in rows:
        forn = str(r[0]) if r[0] else "(NULL)"
        log("  " + forn + ": " + str(r[1]))
    
    conn.close()
    log("Step 8: Done")
except Exception as e:
    log("ERROR at some step: " + str(e))
    log(traceback.format_exc())

f.close()
