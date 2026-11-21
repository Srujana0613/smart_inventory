-- =====================================================================
-- Phase 2: Sample data. Dates are relative to today (CURDATE), so the
-- expiry examples always make sense whenever you run this.
-- =====================================================================
USE smart_inventory_db;

INSERT INTO suppliers (supplier_name, contact_person, phone, email, address) VALUES
('Sri Lakshmi Traders',   'Ramesh Kumar',  '9876500001', 'lakshmi@example.com', 'Guntur, Andhra Pradesh'),
('Amul Dairy Distributors','Suresh Reddy', '9876500002', 'dairy@example.com',   'Vijayawada, Andhra Pradesh'),
('Fresh Bake Foods',      'Anitha Rao',    '9876500003', 'bake@example.com',    'Guntur, Andhra Pradesh');

INSERT INTO categories (category_name) VALUES
('Grocery'), ('Dairy'), ('Bakery'), ('Beverages'), ('Snacks');

INSERT INTO products (sku, product_name, category_id, supplier_id, unit, cost_price, selling_price, reorder_level) VALUES
('GRO-RICE-01', 'Sona Masoori Rice', 1, 1, 'kg',     52.00,  60.00, 30),
('DAI-MILK-01', 'Milk 500ml',        2, 2, 'packet', 24.00,  28.00, 25),
('BAK-BRD-01',  'Bread Loaf',        3, 3, 'pcs',    32.00,  40.00, 15),
('GRO-SUG-01',  'Sugar',             1, 1, 'kg',     40.00,  45.00, 20),
('GRO-OIL-01',  'Sunflower Oil 1L',  1, 1, 'litre', 135.00, 150.00, 20),
('DAI-CRD-01',  'Curd 400g',         2, 2, 'cup',    28.00,  35.00, 15),
('SNK-BIS-01',  'Biscuits Pack',     5, 3, 'pcs',     8.00,  10.00, 40),
('BEV-TEA-01',  'Tea Powder 250g',   4, 1, 'pcs',   100.00, 120.00, 10);

INSERT INTO customers (customer_name, phone, email) VALUES
('Ravi Teja',   '9000000001', 'ravi@example.com'),
('Lakshmi Devi','9000000002', 'lakshmi.d@example.com'),
('Karthik M',   '9000000003', NULL);

-- Batches: note two milk batches with different expiry dates (FEFO demo)
INSERT INTO product_batches
(product_id, batch_number, manufacture_date, expiry_date, quantity_received, quantity_remaining, cost_price, received_date) VALUES
(1, 'RICE-B1', DATE_SUB(CURDATE(), INTERVAL 30 DAY), DATE_ADD(CURDATE(), INTERVAL 300 DAY), 100, 90, 52.00, DATE_SUB(CURDATE(), INTERVAL 20 DAY)),
(2, 'MILK-A',  DATE_SUB(CURDATE(), INTERVAL 2 DAY),  DATE_ADD(CURDATE(), INTERVAL 3 DAY),   50, 20, 24.00, DATE_SUB(CURDATE(), INTERVAL 2 DAY)),
(2, 'MILK-B',  CURDATE(),                            DATE_ADD(CURDATE(), INTERVAL 9 DAY),   60, 60, 24.00, CURDATE()),
(3, 'BRD-B1',  DATE_SUB(CURDATE(), INTERVAL 1 DAY),  DATE_ADD(CURDATE(), INTERVAL 2 DAY),   40, 30, 32.00, DATE_SUB(CURDATE(), INTERVAL 1 DAY)),
(4, 'SUG-B1',  DATE_SUB(CURDATE(), INTERVAL 60 DAY), DATE_ADD(CURDATE(), INTERVAL 400 DAY), 80, 75, 40.00, DATE_SUB(CURDATE(), INTERVAL 25 DAY)),
(5, 'OIL-B1',  DATE_SUB(CURDATE(), INTERVAL 40 DAY), DATE_ADD(CURDATE(), INTERVAL 180 DAY), 60, 55, 135.00, DATE_SUB(CURDATE(), INTERVAL 15 DAY)),
(6, 'CRD-B1',  DATE_SUB(CURDATE(), INTERVAL 1 DAY),  DATE_ADD(CURDATE(), INTERVAL 6 DAY),   30, 30, 28.00, DATE_SUB(CURDATE(), INTERVAL 1 DAY)),
(7, 'BIS-B1',  DATE_SUB(CURDATE(), INTERVAL 30 DAY), DATE_ADD(CURDATE(), INTERVAL 150 DAY), 200, 12, 8.00, DATE_SUB(CURDATE(), INTERVAL 10 DAY)),
(8, 'TEA-B1',  DATE_SUB(CURDATE(), INTERVAL 50 DAY), DATE_ADD(CURDATE(), INTERVAL 250 DAY), 25, 25, 100.00, DATE_SUB(CURDATE(), INTERVAL 12 DAY));

-- Purchase orders: one received, one still pending
INSERT INTO purchase_orders (supplier_id, order_date, expected_date, status, total_amount) VALUES
(2, DATE_SUB(CURDATE(), INTERVAL 3 DAY), DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'RECEIVED', 1200.00),
(1, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 3 DAY), 'PENDING', 5200.00);

INSERT INTO purchase_order_items (po_id, product_id, quantity, unit_cost) VALUES
(1, 2, 50, 24.00),
(2, 1, 100, 52.00);

UPDATE product_batches SET po_item_id = 1 WHERE batch_number = 'MILK-A';

-- Sales (3 bills). batch_id: 2 = MILK-A, 4 = BRD-B1, 5 = SUG-B1, 1 = RICE-B1, 6 = OIL-B1
INSERT INTO sales (customer_id, sale_date, payment_method, discount) VALUES
(1, DATE_SUB(NOW(), INTERVAL 2 DAY), 'UPI',  0),
(2, DATE_SUB(NOW(), INTERVAL 1 DAY), 'CASH', 10),
(NULL, NOW(),                        'CARD', 0);

INSERT INTO sale_items (sale_id, product_id, batch_id, quantity, unit_price) VALUES
(1, 2, 2, 10, 28.00),
(1, 3, 4,  5, 40.00),
(1, 4, 5,  5, 45.00),
(2, 1, 1, 10, 60.00),
(2, 5, 6,  5, 150.00),
(3, 2, 2, 20, 28.00),
(3, 3, 4,  5, 40.00);

-- Bill totals = sum of lines minus discount
UPDATE sales s
SET total_amount = (SELECT SUM(si.quantity * si.unit_price)
                    FROM sale_items si WHERE si.sale_id = s.sale_id) - s.discount;

-- Stock movement audit trail built from existing data
INSERT INTO stock_movements (product_id, batch_id, movement_type, quantity_change, movement_date, notes)
SELECT product_id, batch_id, 'PURCHASE', quantity_received, received_date, 'Initial stock'
FROM product_batches;

INSERT INTO stock_movements (product_id, batch_id, movement_type, quantity_change, movement_date, reference_id, notes)
SELECT si.product_id, si.batch_id, 'SALE', -si.quantity, s.sale_date, si.sale_id, 'Sale'
FROM sale_items si JOIN sales s ON s.sale_id = si.sale_id;
