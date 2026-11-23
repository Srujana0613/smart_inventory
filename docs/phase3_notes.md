# Phase 3: Connecting Python to MySQL

## The 5-step pattern behind every database call
```python
connection = get_connection()            # 1. open a connection
cursor = connection.cursor(dictionary=True)   # 2. create a cursor (sends SQL, holds results)
cursor.execute("SELECT ... WHERE sku = %s", (sku,))  # 3. run SQL
rows = cursor.fetchall()                 # 4. read results   (for INSERT/UPDATE/DELETE: connection.commit())
cursor.close(); connection.close()       # 5. clean up
```
`modules/db_helpers.py` wraps these five steps so you write one line instead:
`fetch_all`, `fetch_one`, `insert`, `execute`.

## Key concepts (interview-ready)

**Cursor**: the object that sends SQL to MySQL and holds the result rows. `dictionary=True` gives rows like `{"product_name": "Milk"}` instead of tuples, so code is readable.

**commit() and rollback()**: INSERT/UPDATE/DELETE are only *proposed* until you `commit()`. `rollback()` undoes everything since the last commit. This is a **transaction**: several steps that succeed or fail *together*. Billing needs this (create sale + reduce stock must never half-happen).

**Parameterized queries**: always write `WHERE sku = %s` and pass `(sku,)` separately. Never use f-strings to build SQL. `demo_phase3.py` section 5 shows an attacker's input `' OR '1'='1` returning every row with an f-string, and nothing with `%s`. This attack is called **SQL injection** and is one of the most common security bugs.

**Context manager (`with db_cursor() as cursor`)**: guarantees the connection is closed and errors trigger a rollback, even if your code crashes.

**`cursor.lastrowid`**: the auto-generated id of the row you just inserted (used later to link a sale to its sale_items).

**`cursor.rowcount`**: how many rows an UPDATE/DELETE changed. `0` means nothing matched.

## Try it yourself (exercises)
Write these in a new file `my_phase3.py` using the helpers. Don't copy; try first.

1. Print every product name with its category name (JOIN).
2. Ask the user for a SKU with `input()` and print that product's details, or "Not found".
3. Insert a new supplier, print its new id, then update its phone number.
4. Print all batches expiring within 10 days, with days left (use `DATEDIFF`).
5. Using Pandas, build a DataFrame of total revenue per product from `sale_items` and print the top 3.
6. Challenge: in ONE transaction, insert a sale and a sale_item; then force an error in the second insert and confirm the sale was NOT saved.

Show me your code when done and I'll review it.

## Common errors
| Error | Meaning |
|---|---|
| `Not all parameters were used` / `Wrong number of arguments` | Count of `%s` doesn't match your tuple. A one-item tuple needs a comma: `(sku,)` |
| `Unread result found` | Call `fetchall()` / `fetchone()` before running another query on the same cursor |
| `Cannot add or update a child row` | Foreign key points to a row that doesn't exist |
| `Duplicate entry` | A UNIQUE column (sku, phone) already has that value |
