-- Lab 4. Baseline plans without additional LAB4 indexes.
-- Run after lab4_01_prepare_data.sql.

\timing on

DROP INDEX IF EXISTS lab4_idx_order_items_product_line_quantity;
DROP INDEX IF EXISTS lab4_idx_order_items_line_total_desc;
DROP INDEX IF EXISTS lab4_idx_order_items_product_line_desc;
DROP INDEX IF EXISTS lab4_idx_order_items_product_only;
DROP INDEX IF EXISTS lab4_idx_order_items_quantity;
DROP INDEX IF EXISTS lab4_idx_users_full_name_pattern;
DROP INDEX IF EXISTS lab4_idx_users_full_name_trgm;
DROP INDEX IF EXISTS lab4_idx_users_email_trgm;
DROP INDEX IF EXISTS lab4_idx_group_orders_title;
DROP INDEX IF EXISTS lab4_idx_participations_order_cover;
DROP INDEX IF EXISTS lab4_idx_order_items_participation_product;
DROP INDEX IF EXISTS lab4_idx_order_items_product_participation;

ANALYZE users;
ANALYZE group_orders;
ANALYZE participations;
ANALYZE order_items;

-- 1. Complex filter: exact product match plus numeric ranges.
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    oi.order_item_id,
    oi.participation_id,
    oi.product_id,
    oi.quantity,
    oi.line_total
FROM order_items oi
WHERE oi.product_id = (
        SELECT MIN(product_id)
        FROM products
        WHERE name = 'LAB4 milk'
    )
  AND oi.line_total BETWEEN 900.00 AND 1800.00
  AND oi.quantity BETWEEN 10 AND 20
ORDER BY oi.line_total, oi.order_item_id
LIMIT 200;

-- 2. ORDER BY with LIMIT: largest order positions.
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    oi.order_item_id,
    oi.participation_id,
    oi.product_id,
    oi.quantity,
    oi.line_total
FROM order_items oi
ORDER BY oi.line_total DESC, oi.order_item_id
LIMIT 100;

-- 3. Query for alternative indexing comparison.
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    oi.order_item_id,
    oi.participation_id,
    oi.quantity,
    oi.line_total
FROM order_items oi
WHERE oi.product_id = (
        SELECT MIN(product_id)
        FROM products
        WHERE name = 'LAB4 cheese'
    )
ORDER BY oi.line_total DESC, oi.order_item_id
LIMIT 200;

-- 4. Text search: prefix, substring, and suffix.
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, full_name, email
FROM users
WHERE full_name LIKE 'Lab4 Buyer 099%'
ORDER BY full_name
LIMIT 100;

EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, full_name, email
FROM users
WHERE full_name ILIKE '%0999%'
ORDER BY user_id
LIMIT 100;

EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, full_name, email
FROM users
WHERE email ILIKE '%9999@lab4.example.com'
ORDER BY user_id
LIMIT 100;

-- 5. JOIN across the existing schema.
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    u.user_id,
    u.email,
    SUM(oi.line_total) AS total_amount
FROM group_orders go
JOIN participations p
    ON p.group_order_id = go.group_order_id
JOIN users u
    ON u.user_id = p.user_id
JOIN order_items oi
    ON oi.participation_id = p.participation_id
WHERE go.title = 'LAB4 bulk order 01'
  AND oi.product_id = (
        SELECT MIN(product_id)
        FROM products
        WHERE name = 'LAB4 potatoes'
    )
GROUP BY u.user_id, u.email
ORDER BY total_amount DESC
LIMIT 100;

-- 6. Negative scenario: low-selectivity predicate.
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM order_items oi
WHERE (oi.quantity + 0) > 0;
