-- =====================================================================
-- Phase 2: Database schema for smart_inventory_db
-- Run order: 01_schema.sql -> 02_sample_data.sql
-- WARNING: this script DROPS and recreates all tables (data is lost).
-- =====================================================================

CREATE DATABASE IF NOT EXISTS smart_inventory_db;
USE smart_inventory_db;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS stock_movements;
DROP TABLE IF EXISTS sale_items;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS product_batches;
DROP TABLE IF EXISTS purchase_order_items;
DROP TABLE IF EXISTS purchase_orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS suppliers;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- 1. suppliers: companies we buy stock from
-- ---------------------------------------------------------------------
CREATE TABLE suppliers (
    supplier_id     INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name   VARCHAR(100) NOT NULL,
    contact_person  VARCHAR(100),
    phone           VARCHAR(15),
    email           VARCHAR(100),
    address         VARCHAR(255),
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- 2. categories: Dairy, Grocery, Bakery ...
-- ---------------------------------------------------------------------
CREATE TABLE categories (
    category_id     INT AUTO_INCREMENT PRIMARY KEY,
    category_name   VARCHAR(50) NOT NULL UNIQUE
);

-- ---------------------------------------------------------------------
-- 3. products: WHAT we sell (one row per product, not per packet)
-- ---------------------------------------------------------------------
CREATE TABLE products (
    product_id      INT AUTO_INCREMENT PRIMARY KEY,
    sku             VARCHAR(30)  NOT NULL UNIQUE,
    product_name    VARCHAR(100) NOT NULL,
    category_id     INT NOT NULL,
    supplier_id     INT,
    unit            VARCHAR(15) NOT NULL DEFAULT 'pcs',
    cost_price      DECIMAL(10,2) NOT NULL,
    selling_price   DECIMAL(10,2) NOT NULL,
    reorder_level   INT NOT NULL DEFAULT 10,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_product_prices CHECK (cost_price >= 0 AND selling_price >= 0),
    CONSTRAINT chk_reorder_level  CHECK (reorder_level >= 0),
    CONSTRAINT fk_products_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id),
    CONSTRAINT fk_products_supplier FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id) ON DELETE SET NULL
);

-- ---------------------------------------------------------------------
-- 4. customers
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id     INT AUTO_INCREMENT PRIMARY KEY,
    customer_name   VARCHAR(100) NOT NULL,
    phone           VARCHAR(15) UNIQUE,
    email           VARCHAR(100),
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- 5. purchase_orders: an order we place with a supplier
-- ---------------------------------------------------------------------
CREATE TABLE purchase_orders (
    po_id           INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id     INT NOT NULL,
    order_date      DATE NOT NULL,
    expected_date   DATE,
    status          ENUM('PENDING','RECEIVED','CANCELLED') NOT NULL DEFAULT 'PENDING',
    total_amount    DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id)
);

-- ---------------------------------------------------------------------
-- 6. purchase_order_items: the lines inside one purchase order
-- ---------------------------------------------------------------------
CREATE TABLE purchase_order_items (
    po_item_id      INT AUTO_INCREMENT PRIMARY KEY,
    po_id           INT NOT NULL,
    product_id      INT NOT NULL,
    quantity        INT NOT NULL,
    unit_cost       DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_poi_quantity CHECK (quantity > 0),
    CONSTRAINT fk_poi_po FOREIGN KEY (po_id)
        REFERENCES purchase_orders(po_id) ON DELETE CASCADE,
    CONSTRAINT fk_poi_product FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);

-- ---------------------------------------------------------------------
-- 7. product_batches: ACTUAL stock. Each delivery of a product is a batch
--    with its own expiry date. This table makes FEFO possible.
-- ---------------------------------------------------------------------
CREATE TABLE product_batches (
    batch_id            INT AUTO_INCREMENT PRIMARY KEY,
    product_id          INT NOT NULL,
    batch_number        VARCHAR(40) NOT NULL,
    po_item_id          INT,
    manufacture_date    DATE,
    expiry_date         DATE NOT NULL,
    quantity_received   INT NOT NULL,
    quantity_remaining  INT NOT NULL,
    cost_price          DECIMAL(10,2) NOT NULL,
    received_date       DATE NOT NULL,
    CONSTRAINT uq_batch UNIQUE (product_id, batch_number),
    CONSTRAINT chk_batch_qty CHECK (
        quantity_received > 0
        AND quantity_remaining >= 0
        AND quantity_remaining <= quantity_received
    ),
    CONSTRAINT fk_batch_product FOREIGN KEY (product_id)
        REFERENCES products(product_id),
    CONSTRAINT fk_batch_poitem FOREIGN KEY (po_item_id)
        REFERENCES purchase_order_items(po_item_id) ON DELETE SET NULL
);
CREATE INDEX idx_batch_expiry ON product_batches (product_id, expiry_date);

-- ---------------------------------------------------------------------
-- 8. sales: one bill / invoice
-- ---------------------------------------------------------------------
CREATE TABLE sales (
    sale_id         INT AUTO_INCREMENT PRIMARY KEY,
    customer_id     INT,
    sale_date       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_method  ENUM('CASH','CARD','UPI') NOT NULL DEFAULT 'CASH',
    discount        DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount    DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id) ON DELETE SET NULL
);
CREATE INDEX idx_sales_date ON sales (sale_date);

-- ---------------------------------------------------------------------
-- 9. sale_items: the lines on a bill. batch_id records WHICH batch the
--    stock came from (needed for FEFO and for profit calculation).
-- ---------------------------------------------------------------------
CREATE TABLE sale_items (
    sale_item_id    INT AUTO_INCREMENT PRIMARY KEY,
    sale_id         INT NOT NULL,
    product_id      INT NOT NULL,
    batch_id        INT NOT NULL,
    quantity        INT NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_si_quantity CHECK (quantity > 0),
    CONSTRAINT fk_si_sale FOREIGN KEY (sale_id)
        REFERENCES sales(sale_id) ON DELETE CASCADE,
    CONSTRAINT fk_si_product FOREIGN KEY (product_id)
        REFERENCES products(product_id),
    CONSTRAINT fk_si_batch FOREIGN KEY (batch_id)
        REFERENCES product_batches(batch_id)
);

-- ---------------------------------------------------------------------
-- 10. stock_movements: audit trail. Every stock change gets a row.
--     quantity_change is positive (stock in) or negative (stock out).
-- ---------------------------------------------------------------------
CREATE TABLE stock_movements (
    movement_id     INT AUTO_INCREMENT PRIMARY KEY,
    product_id      INT NOT NULL,
    batch_id        INT,
    movement_type   ENUM('PURCHASE','SALE','ADJUSTMENT','EXPIRED','RETURN') NOT NULL,
    quantity_change INT NOT NULL,
    movement_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reference_id    INT,
    notes           VARCHAR(255),
    CONSTRAINT fk_sm_product FOREIGN KEY (product_id)
        REFERENCES products(product_id),
    CONSTRAINT fk_sm_batch FOREIGN KEY (batch_id)
        REFERENCES product_batches(batch_id) ON DELETE SET NULL
);
CREATE INDEX idx_sm_product_date ON stock_movements (product_id, movement_date);
