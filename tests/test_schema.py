"""Checks that the Phase 2 schema exists and the constraints work.

Run from the project root:  python -m unittest tests.test_schema -v
(First run: python -m modules.setup_database)
"""
import unittest

import mysql.connector

from modules.db_connection import get_connection

EXPECTED_TABLES = {
    "suppliers", "categories", "products", "customers", "purchase_orders",
    "purchase_order_items", "product_batches", "sales", "sale_items",
    "stock_movements",
}


class TestSchema(unittest.TestCase):
    def setUp(self):
        self.conn = get_connection()
        self.cur = self.conn.cursor()

    def tearDown(self):
        self.conn.rollback()
        self.cur.close()
        self.conn.close()

    def test_all_tables_exist(self):
        self.cur.execute("SHOW TABLES")
        tables = {row[0] for row in self.cur.fetchall()}
        self.assertTrue(EXPECTED_TABLES.issubset(tables))

    def test_duplicate_sku_rejected(self):
        sql = ("INSERT INTO products (sku, product_name, category_id, cost_price, selling_price) "
               "VALUES ('GRO-RICE-01', 'Duplicate', 1, 1, 2)")
        with self.assertRaises(mysql.connector.Error):
            self.cur.execute(sql)

    def test_foreign_key_enforced(self):
        sql = ("INSERT INTO products (sku, product_name, category_id, cost_price, selling_price) "
               "VALUES ('X-1', 'Bad category', 9999, 1, 2)")
        with self.assertRaises(mysql.connector.Error):
            self.cur.execute(sql)

    def test_negative_stock_rejected(self):
        with self.assertRaises(mysql.connector.Error):
            self.cur.execute("UPDATE product_batches SET quantity_remaining = -5 WHERE batch_id = 1")


if __name__ == "__main__":
    unittest.main()
