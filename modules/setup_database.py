"""Phase 2: builds the database from the SQL files.

Run from the project root:
    python -m modules.setup_database            -> schema + sample data
    python -m modules.setup_database --no-data  -> schema only

WARNING: this recreates every table, so existing data is deleted.
"""
import sys
from pathlib import Path

import mysql.connector

from modules.db_connection import get_connection

SQL_DIR = Path(__file__).resolve().parent.parent / "database"


def read_statements(sql_file):
    """Split a .sql file into individual statements (skips -- comments)."""
    lines = []
    for line in sql_file.read_text(encoding="utf-8").splitlines():
        if line.strip().startswith("--"):
            continue
        lines.append(line)
    return [s.strip() for s in "\n".join(lines).split(";") if s.strip()]


def run_sql_file(cursor, filename):
    print(f"Running {filename} ...")
    for statement in read_statements(SQL_DIR / filename):
        cursor.execute(statement)


def main():
    load_sample_data = "--no-data" not in sys.argv
    connection = get_connection(use_database=False)
    cursor = connection.cursor()
    try:
        run_sql_file(cursor, "01_schema.sql")
        if load_sample_data:
            run_sql_file(cursor, "02_sample_data.sql")
        connection.commit()

        cursor.execute("USE smart_inventory_db")
        cursor.execute("SHOW TABLES")
        tables = [row[0] for row in cursor.fetchall()]
        print(f"\nDatabase ready with {len(tables)} tables:")
        for table in tables:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            print(f"  {table:<22} {cursor.fetchone()[0]} rows")
    except mysql.connector.Error as error:
        connection.rollback()
        print("\nDatabase setup failed:", error)
        sys.exit(1)
    finally:
        cursor.close()
        connection.close()


if __name__ == "__main__":
    main()
