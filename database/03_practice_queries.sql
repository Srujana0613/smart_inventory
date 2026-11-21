-- =====================================================================
-- Practice queries. Run them ONE AT A TIME in MySQL Workbench
-- (select the query, then press Ctrl+Enter) and read the results.
-- =====================================================================
USE smart_inventory_db;

-- 1. SELECT + WHERE: all active products
SELECT product_id, product_name, selling_price FROM products WHERE is_active = TRUE;

-- 2. INNER JOIN: each product with its category and supplier
SELECT p.product_name, c.category_name, s.supplier_name
FROM products p
JOIN categories c ON c.category_id = p.category_id
LEFT JOIN suppliers s ON s.supplier_id = p.supplier_id;

-- 3. GROUP BY + SUM: total stock per product (adds up all batches)
SELECT p.product_name, SUM(b.quantity_remaining) AS total_stock
FROM products p
JOIN product_batches b ON b.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_stock DESC;

-- 4. HAVING: LOW STOCK (stock at or below reorder level)
SELECT p.product_name, SUM(b.quantity_remaining) AS total_stock, p.reorder_level
FROM products p
JOIN product_batches b ON b.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.reorder_level
HAVING total_stock <= p.reorder_level;

-- 5. EXPIRY ALERT: batches expiring within 7 days
SELECT p.product_name, b.batch_number, b.expiry_date,
       DATEDIFF(b.expiry_date, CURDATE()) AS days_left, b.quantity_remaining
FROM product_batches b
JOIN products p ON p.product_id = b.product_id
WHERE b.quantity_remaining > 0
  AND b.expiry_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
ORDER BY b.expiry_date;

-- 6. FEFO: which milk batch should be sold FIRST? (earliest expiry first)
SELECT batch_id, batch_number, expiry_date, quantity_remaining
FROM product_batches
WHERE product_id = 2 AND quantity_remaining > 0 AND expiry_date >= CURDATE()
ORDER BY expiry_date ASC;

-- 7. Multi-table JOIN: full bill details
SELECT s.sale_id, s.sale_date, COALESCE(c.customer_name, 'Walk-in') AS customer,
       p.product_name, si.quantity, si.unit_price,
       si.quantity * si.unit_price AS line_total
FROM sales s
LEFT JOIN customers c ON c.customer_id = s.customer_id
JOIN sale_items si ON si.sale_id = s.sale_id
JOIN products p ON p.product_id = si.product_id
ORDER BY s.sale_id;

-- 8. Profit per product (selling price - batch cost price)
SELECT p.product_name,
       SUM(si.quantity * si.unit_price) AS revenue,
       SUM(si.quantity * b.cost_price)  AS cost,
       SUM(si.quantity * (si.unit_price - b.cost_price)) AS profit
FROM sale_items si
JOIN products p ON p.product_id = si.product_id
JOIN product_batches b ON b.batch_id = si.batch_id
GROUP BY p.product_id, p.product_name
ORDER BY profit DESC;

-- 9. SUBQUERY: products priced above the average selling price
SELECT product_name, selling_price FROM products
WHERE selling_price > (SELECT AVG(selling_price) FROM products);

-- 10. Products that have NEVER been sold
SELECT product_name FROM products
WHERE product_id NOT IN (SELECT DISTINCT product_id FROM sale_items);

-- 11. Daily sales summary
SELECT DATE(sale_date) AS day, COUNT(*) AS bills, SUM(total_amount) AS revenue
FROM sales GROUP BY DATE(sale_date) ORDER BY day;

-- 12. Audit trail: stock movement history for Milk
SELECT movement_date, movement_type, quantity_change, batch_id
FROM stock_movements WHERE product_id = 2 ORDER BY movement_date;
