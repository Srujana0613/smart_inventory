"""Reusable database connection used by every module in the project."""
import os

import mysql.connector
from dotenv import load_dotenv

load_dotenv()


def get_connection(use_database=True):
    """Return a new MySQL connection using the values in the .env file.

    use_database=False connects to the MySQL server only (no database selected).
    That is needed when the database itself does not exist yet.
    """
    config = {
        "host": os.getenv("DB_HOST", "localhost"),
        "user": os.getenv("DB_USER", "root"),
        "password": os.getenv("DB_PASSWORD", ""),
    }
    if use_database:
        config["database"] = os.getenv("DB_NAME", "smart_inventory_db")
    return mysql.connector.connect(**config)
