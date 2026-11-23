"""Tests for modules/db_helpers.py

Run from the project root:  python -m unittest tests.test_db_helpers -v
"""
import unittest

import mysql.connector

from modules.db_helpers import db_cursor, execute, fetch_all, fetch_one, insert

SKU = "TEST-PH3"


class TestDbHelpers(unittest.TestCase):
    def setUp(self):
        execute("DELETE FROM products WHERE sku = %s", (SKU,))

    def tearDown(self):
        execute("DELETE FROM products WHERE sku = %s", (SKU,))
        execute("DELETE FROM categories WHERE category_name = %s", ("Rollback Test",))

    def test_fetch_all_returns_list_of_dicts(self):
        rows = fetch_all("SELECT * FROM products")
        self.assertGreaterEqual(len(rows), 8)
        self.assertIn("product_name", rows[0])

    def test_fetch_one_missing_returns_none(self):
        self.assertIsNone(fetch_one("SELECT * FROM products WHERE sku = %s", ("NOPE",)))

    def test_insert_update_delete_roundtrip(self):
        new_id = insert(
            "INSERT INTO products (sku, product_name, category_id, cost_price, selling_price) "
            "VALUES (%s, %s, %s, %s, %s)", (SKU, "Test item", 1, 5, 8))
        self.assertGreater(new_id, 0)
        self.assertEqual(execute("UPDATE products SET selling_price = %s WHERE product_id = %s", (9, new_id)), 1)
        row = fetch_one("SELECT selling_price FROM products WHERE product_id = %s", (new_id,))
        self.assertEqual(float(row["selling_price"]), 9.0)
        self.assertEqual(execute("DELETE FROM products WHERE product_id = %s", (new_id,)), 1)

    def test_injection_text_is_treated_as_plain_data(self):
        rows = fetch_all("SELECT * FROM products WHERE sku = %s", ("' OR '1'='1",))
        self.assertEqual(rows, [])

    def test_error_rolls_back_whole_transaction(self):
        with self.assertRaises(mysql.connector.Error):
            with db_cursor(commit=True) as cur:
                cur.execute("INSERT INTO categories (category_name) VALUES ('Rollback Test')")
                cur.execute("INSERT INTO products (sku, product_name, category_id, cost_price, selling_price) "
                            "VALUES ('BAD', 'Bad', 9999, 1, 2)")
        row = fetch_one("SELECT COUNT(*) AS n FROM categories WHERE category_name = 'Rollback Test'")
        self.assertEqual(row["n"], 0)


if __name__ == "__main__":
    unittest.main()
