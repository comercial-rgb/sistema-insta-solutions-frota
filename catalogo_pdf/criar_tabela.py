# criar_tabela.py — Cria a tabela catalogo_pecas no MySQL
# Rode UMA VEZ antes de importar os catálogos
# Uso: python criar_tabela.py

import pymysql

DB_CONFIG = {
    "host": "127.0.0.1",
    "port": 3306,
    "db": "sistema_insta_solutions_development",
    "user": "root",
    "password": "rot123",
    "charset": "utf8mb4"
}

SQL_CREATE = """
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
    importado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_catalogo (fornecedor, marca(50), veiculo(50), modelo(50), motor(50), ano_inicio, ano_fim, grupo_produto(80), produto(80))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"""

SQL_INDEXES = [
    "CREATE INDEX idx_catalogo_marca ON catalogo_pecas(marca);",
    "CREATE INDEX idx_catalogo_veiculo ON catalogo_pecas(veiculo, modelo);",
    "CREATE INDEX idx_catalogo_produto ON catalogo_pecas(produto);",
    "CREATE INDEX idx_catalogo_fornecedor ON catalogo_pecas(fornecedor);",
]

def main():
    print("Conectando ao MySQL...")
    try:
        conn = pymysql.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print("Conexao estabelecida!")
    except Exception as e:
        print(f"Erro na conexao: {e}")
        return

    print("Criando tabela catalogo_pecas...")
    cursor.execute(SQL_CREATE)
    conn.commit()
    print("Tabela criada!")

    for sql in SQL_INDEXES:
        try:
            cursor.execute(sql)
            conn.commit()
        except pymysql.err.OperationalError as e:
            if "Duplicate key name" in str(e):
                pass  # indice ja existe
            else:
                print(f"  Aviso indice: {e}")

    print("Indices criados!")

    cursor.close()
    conn.close()
    print("\nTabela pronta para importacao!")


if __name__ == "__main__":
    main()
