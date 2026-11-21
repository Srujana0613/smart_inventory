"""Reusable database connection used by every module in the project."""
import os

import mysql.connector
from dotenv import load_dotenv

load_dotenv()


def get_connection():
    """Return a new MySQL connection using the values in the .env file."""
    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "localhost"),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "smart_inventory_db"),
    )
