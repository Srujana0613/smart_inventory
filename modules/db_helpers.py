"""Phase 3: small helper functions for talking to MySQL from Python.

Every later module (products, sales, suppliers ...) will use these helpers
instead of repeating connection / cursor / commit code.

IMPORTANT RULE: never build SQL by pasting values into a string.
Always use %s placeholders and pass the values separately:

    fetch_all("SELECT * FROM products WHERE sku = %s", (sku,))
"""
from contextlib import contextmanager

from modules.db_connection import get_connection


@contextmanager
def db_cursor(commit=False):
    """Open a connection + cursor, and always clean up afterwards.

    commit=True  -> save the changes if everything succeeds.
    On any error the changes are rolled back (undone) and the error is re-raised.
    Rows are returned as dictionaries, e.g. row["product_name"].
    """
    connection = get_connection()
    cursor = connection.cursor(dictionary=True)
    try:
        yield cursor
        if commit:
            connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        cursor.close()
        connection.close()


def fetch_all(query, params=None):
    """Run a SELECT and return all rows as a list of dictionaries."""
    with db_cursor() as cursor:
        cursor.execute(query, params or ())
        return cursor.fetchall()


def fetch_one(query, params=None):
    """Run a SELECT and return the first row as a dictionary (or None)."""
    with db_cursor() as cursor:
        cursor.execute(query, params or ())
        return cursor.fetchone()


def insert(query, params=None):
    """Run an INSERT, save it, and return the new row's auto-generated id."""
    with db_cursor(commit=True) as cursor:
        cursor.execute(query, params or ())
        return cursor.lastrowid


def execute(query, params=None):
    """Run an UPDATE or DELETE, save it, and return how many rows changed."""
    with db_cursor(commit=True) as cursor:
        cursor.execute(query, params or ())
        return cursor.rowcount
