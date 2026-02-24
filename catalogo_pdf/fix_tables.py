import sys
import pymysql

def log(msg):
    print(msg, flush=True)

try:
    conn = pymysql.connect(
        host='127.0.0.1', port=3306,
        db='sistema_insta_solutions_development',
        user='root', password='rot123',
        charset='utf8mb4',
        autocommit=True,
        connect_timeout=10,
        read_timeout=600,
        write_timeout=600
    )
    cur = conn.cursor()

    # Step 1: Check tables
    log("=" * 60)
    log("STEP 1: Checking tables")
    log("=" * 60)
    cur.execute("SHOW TABLES LIKE 'catalogo_pecas%'")
    tables = [t[0] for t in cur.fetchall()]
    log(f"  Tables found: {tables}")

    has_main = 'catalogo_pecas' in tables
    has_dedup = 'catalogo_pecas_dedup' in tables

    # Fast approximate counts via information_schema
    cur.execute("""
        SELECT TABLE_NAME, TABLE_ROWS 
        FROM information_schema.TABLES 
        WHERE TABLE_SCHEMA = 'sistema_insta_solutions_development' 
        AND TABLE_NAME LIKE 'catalogo_pecas%%'
    """)
    for row in cur.fetchall():
        log(f"    {row[0]}: ~{row[1]:,} rows (approx)")

    # Step 2: Fix
    log("")
    log("=" * 60)
    log("STEP 2: Fixing table structure")
    log("=" * 60)

    if has_dedup and not has_main:
        log("  Case: Only dedup exists -> Renaming to catalogo_pecas...")
        cur.execute("RENAME TABLE catalogo_pecas_dedup TO catalogo_pecas")
        log("  -> Renamed OK!")

    elif has_dedup and has_main:
        log("  Case: Both tables exist.")
        cur.execute("SELECT id FROM catalogo_pecas LIMIT 1")
        main_has_data = cur.fetchone() is not None
        cur.execute("SELECT id FROM catalogo_pecas_dedup LIMIT 1")
        dedup_has_data = cur.fetchone() is not None
        log(f"    catalogo_pecas has data: {main_has_data}")
        log(f"    catalogo_pecas_dedup has data: {dedup_has_data}")

        if dedup_has_data and not main_has_data:
            log("  -> Main empty, dedup has data. Dropping main, renaming dedup...")
            cur.execute("DROP TABLE catalogo_pecas")
            cur.execute("RENAME TABLE catalogo_pecas_dedup TO catalogo_pecas")
            log("  -> Done!")
        elif dedup_has_data and main_has_data:
            log("  -> Both have data. Dropping dedup, keeping main...")
            cur.execute("DROP TABLE catalogo_pecas_dedup")
            log("  -> Running in-place dedup DELETE (may take a while)...")
            cur.execute("""
                DELETE t1 FROM catalogo_pecas t1
                INNER JOIN catalogo_pecas t2
                WHERE t1.id > t2.id
                  AND t1.produto = t2.produto
                  AND t1.marca = t2.marca
                  AND t1.veiculo = t2.veiculo
                  AND t1.modelo = t2.modelo
                  AND t1.fornecedor = t2.fornecedor
            """)
            log(f"  -> Deleted {cur.rowcount:,} duplicate rows.")
        else:
            log("  -> Dedup empty. Dropping dedup, keeping main...")
            cur.execute("DROP TABLE catalogo_pecas_dedup")
            log("  -> Done!")

    elif has_main and not has_dedup:
        log("  Case: Only catalogo_pecas exists (normal). Nothing to fix.")

    else:
        log("  ERROR: No tables found!")
        sys.exit(1)

    # Step 3: Indices
    log("")
    log("=" * 60)
    log("STEP 3: Checking/Recreating indices")
    log("=" * 60)

    cur.execute("SHOW INDEX FROM catalogo_pecas")
    existing = set(row[2] for row in cur.fetchall())
    log(f"  Existing indices: {sorted(existing)}")

    cur.execute("SHOW COLUMNS FROM catalogo_pecas LIKE 'id'")
    id_info = cur.fetchone()
    log(f"  ID column: {id_info}")

    if 'PRIMARY' not in existing:
        log("  -> Adding PRIMARY KEY on id...")
        try:
            cur.execute("ALTER TABLE catalogo_pecas ADD PRIMARY KEY (id)")
            log("  -> OK")
        except Exception as e:
            log(f"  -> {e}")

    if id_info and 'auto_increment' not in str(id_info).lower():
        log("  -> Setting AUTO_INCREMENT on id...")
        try:
            cur.execute("ALTER TABLE catalogo_pecas MODIFY id BIGINT NOT NULL AUTO_INCREMENT")
            log("  -> OK")
        except Exception as e:
            log(f"  -> {e}")

    indices = {
        'idx_marca': "CREATE INDEX idx_marca ON catalogo_pecas (marca(191))",
        'idx_veiculo_modelo': "CREATE INDEX idx_veiculo_modelo ON catalogo_pecas (veiculo(100), modelo(100))",
        'idx_produto': "CREATE INDEX idx_produto ON catalogo_pecas (produto(191))",
        'idx_fornecedor': "CREATE INDEX idx_fornecedor ON catalogo_pecas (fornecedor(191))",
    }
    for name, sql in indices.items():
        if name not in existing:
            log(f"  -> Creating {name}...")
            try:
                cur.execute(sql)
                log(f"  -> OK")
            except Exception as e:
                log(f"  -> {e}")
        else:
            log(f"  {name} already exists.")

    cur.execute("SHOW INDEX FROM catalogo_pecas")
    final = sorted(set(row[2] for row in cur.fetchall()))
    log(f"  Final indices: {final}")

    # Step 4: Count per fornecedor
    log("")
    log("=" * 60)
    log("STEP 4: Count per fornecedor")
    log("=" * 60)
    cur.execute("""
        SELECT fornecedor, COUNT(*) as c 
        FROM catalogo_pecas 
        GROUP BY fornecedor 
        ORDER BY c DESC
    """)
    rows = cur.fetchall()
    total = 0
    for r in rows:
        log(f"  {str(r[0]):30s} {r[1]:>8,}")
        total += r[1]
    log(f"  {'TOTAL':30s} {total:>8,}")

    conn.close()
    log("")
    log("ALL DONE!")

except Exception as e:
    print(f"FATAL ERROR: {type(e).__name__}: {e}", flush=True)
    import traceback
    traceback.print_exc()
    sys.exit(1)
