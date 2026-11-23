"""Phase 3 demo: read, insert, update, delete, SQL injection, rollback, pandas.

Run from the project root:  python demo_phase3.py
It cleans up after itself, so you can run it as many times as you like.
Read the code top to bottom: every section has a comment explaining it.
"""
import mysql.connector
import pandas as pd

from modules.db_connection import get_connection
from modules.db_helpers import execute, fetch_all, fetch_one, insert

DEMO_SKU = "DEMO-001"


def heading(text):
    print(f"\n=== {text} ===")


# ---------------------------------------------------------------- 1. READ
heading("1. Read: all products")
for p in fetch_all("SELECT product_id, product_name, selling_price FROM products"):
    print(f"  {p['product_id']}. {p['product_name']:<20} Rs.{p['selling_price']}")

# ------------------------------------------------- 2. READ with a parameter
heading("2. Read one product using a safe %s placeholder")
product = fetch_one("SELECT * FROM products WHERE sku = %s", ("DAI-MILK-01",))
print("  Found:", product["product_name"], "| reorder level:", product["reorder_level"])

# ---------------------------------------------------------------- 3. INSERT
heading("3. Insert a new product")
execute("DELETE FROM products WHERE sku = %s", (DEMO_SKU,))  # clean old demo row
new_id = insert(
    """INSERT INTO products (sku, product_name, category_id, supplier_id, unit,
                           cost_price, selling_price, reorder_level)
       VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
    (DEMO_SKU, "Demo Salt 1kg", 1, 1, "kg", 12.00, 18.00, 20),
)
print("  New product_id =", new_id)

# ---------------------------------------------------------------- 4. UPDATE
heading("4. Update its price")
changed = execute("UPDATE products SET selling_price = %s WHERE product_id = %s", (20.00, new_id))
print("  Rows changed:", changed)
print("  New price:", fetch_one("SELECT selling_price FROM products WHERE product_id = %s", (new_id,))["selling_price"])

# -------------------------------------------------- 5. SQL INJECTION DEMO
heading("5. Why we never paste values into SQL (SQL injection)")
evil_input = "' OR '1'='1"          # what an attacker might type into a search box

unsafe_query = f"SELECT product_name FROM products WHERE sku = '{evil_input}'"
print("  UNSAFE query text:", unsafe_query)
print("  UNSAFE returns", len(fetch_all(unsafe_query)), "rows  <-- it leaked EVERY product!")

safe_rows = fetch_all("SELECT product_name FROM products WHERE sku = %s", (evil_input,))
print("  SAFE   returns", len(safe_rows), "rows  <-- the input is treated as plain text")

# --------------------------------------------------- 6. TRANSACTION ROLLBACK
heading("6. Transaction: all steps succeed together, or none do")
connection = get_connection()
cursor = connection.cursor()
try:
    cursor.execute("INSERT INTO categories (category_name) VALUES ('Temp Category')")
    print("  Step 1 done: inserted 'Temp Category' (not saved yet)")
    # Step 2 is deliberately wrong: category_id 9999 does not exist
    cursor.execute(
        "INSERT INTO products (sku, product_name, category_id, cost_price, selling_price) "
        "VALUES ('BAD-1', 'Bad product', 9999, 1, 2)"
    )
    connection.commit()
except mysql.connector.Error as error:
    connection.rollback()
    print("  Step 2 failed:", error.msg[:60], "...")
    print("  -> rollback() undid step 1 as well")
finally:
    cursor.close()
    connection.close()
leftover = fetch_one("SELECT COUNT(*) AS n FROM categories WHERE category_name = 'Temp Category'")
print("  'Temp Category' rows left in database:", leftover["n"])

# ------------------------------------------------------------ 7. PANDAS
heading("7. Load a query into a Pandas DataFrame")
df = pd.DataFrame(fetch_all(
    """SELECT p.product_name, SUM(b.quantity_remaining) AS stock, p.reorder_level
       FROM products p JOIN product_batches b ON b.product_id = p.product_id
       GROUP BY p.product_id, p.product_name, p.reorder_level"""
))
df["stock"] = df["stock"].astype(int)
df["needs_reorder"] = df["stock"] <= df["reorder_level"]
print(df.to_string(index=False))

# ---------------------------------------------------------------- 8. DELETE
heading("8. Delete the demo product (clean up)")
print("  Rows deleted:", execute("DELETE FROM products WHERE product_id = %s", (new_id,)))
print("\nPhase 3 demo finished successfully.")
