import pymysql
conn = pymysql.connect(host='127.0.0.1', port=3306, db='sistema_insta_solutions_development', user='root', password='rot123', charset='utf8mb4')
cur = conn.cursor()
cur.execute('SELECT fornecedor, COUNT(*) as c FROM catalogo_pecas GROUP BY fornecedor ORDER BY c DESC')
for r in cur.fetchall():
    print(f'{r[0]:30s} {r[1]:>8d}')
cur.execute('SELECT COUNT(*) FROM catalogo_pecas')
print(f'TOTAL: {cur.fetchone()[0]}')
conn.close()
