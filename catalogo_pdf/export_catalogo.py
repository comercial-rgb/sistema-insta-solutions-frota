"""Export catalogo_pecas to SQL INSERT statements for production import"""
import pymysql

conn = pymysql.connect(host='127.0.0.1', port=3306, db='sistema_insta_solutions_development',
                       user='root', password='rot123', charset='utf8mb4')
cur = conn.cursor()

# Get column names
cur.execute("SHOW COLUMNS FROM catalogo_pecas")
columns = [r[0] for r in cur.fetchall()]
cols_str = ', '.join(f'`{c}`' for c in columns)

# Count total
cur.execute("SELECT COUNT(*) FROM catalogo_pecas")
total = cur.fetchone()[0]
print(f"Exporting {total} records...", flush=True)

BATCH = 5000
offset = 0
written = 0

with open('catalogo_pecas_data.sql', 'w', encoding='utf-8') as f:
    # Header
    f.write("-- catalogo_pecas data export\n")
    f.write("SET NAMES utf8mb4;\n")
    f.write("SET sql_mode = '';\n")
    f.write("SET FOREIGN_KEY_CHECKS = 0;\n\n")
    f.write("-- Clear existing data\n")
    f.write("TRUNCATE TABLE catalogo_pecas;\n\n")
    
    while offset < total:
        cur.execute(f"SELECT {cols_str} FROM catalogo_pecas ORDER BY id LIMIT {BATCH} OFFSET {offset}")
        rows = cur.fetchall()
        if not rows:
            break
        
        # Build INSERT statement
        values_list = []
        for row in rows:
            vals = []
            for v in row:
                if v is None:
                    vals.append('NULL')
                elif isinstance(v, (int, float)):
                    vals.append(str(v))
                else:
                    escaped = str(v).replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n").replace("\r", "\\r")
                    vals.append(f"'{escaped}'")
            values_list.append(f"({', '.join(vals)})")
        
        f.write(f"INSERT INTO `catalogo_pecas` ({cols_str}) VALUES\n")
        f.write(',\n'.join(values_list))
        f.write(';\n\n')
        
        written += len(rows)
        offset += BATCH
        if written % 50000 == 0 or written == total:
            print(f"  {written}/{total} ({written*100//total}%)", flush=True)

    f.write("\nSET FOREIGN_KEY_CHECKS = 1;\n")

print(f"\nDone! Exported {written} records to catalogo_pecas_data.sql", flush=True)
conn.close()

import os
size = os.path.getsize('catalogo_pecas_data.sql')
print(f"File size: {size:,} bytes ({size/1024/1024:.1f} MB)", flush=True)
