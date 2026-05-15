-- Lab 4. Impact of additional indexes on INSERT and UPDATE.
-- The benchmark uses only rows with product 'LAB4 benchmark item'.

\timing on

DROP INDEX IF EXISTS lab4_idx_order_items_product_line_quantity;
DROP INDEX IF EXISTS lab4_idx_order_items_line_total_desc;
DROP INDEX IF EXISTS lab4_idx_order_items_product_line_desc;
DROP INDEX IF EXISTS lab4_idx_order_items_product_only;
DROP INDEX IF EXISTS lab4_idx_order_items_quantity;
DROP INDEX IF EXISTS lab4_idx_order_items_participation_product;
DROP INDEX IF EXISTS lab4_idx_order_items_product_participation;

DELETE FROM order_items oi
USING products pr
WHERE oi.product_id = pr.product_id
  AND pr.name = 'LAB4 benchmark item';

ANALYZE order_items;

-- INSERT without additional LAB4 indexes.
EXPLAIN (ANALYZE, BUFFERS)
WITH target_product AS (
    SELECT product_id, price
    FROM products
    WHERE name = 'LAB4 benchmark item'
    ORDER BY product_id
    LIMIT 1
),
participant_pool AS (
    SELECT
        p.participation_id,
        ROW_NUMBER() OVER (ORDER BY p.participation_id) AS rn
    FROM participations p
    JOIN group_orders go
        ON go.group_order_id = p.group_order_id
    WHERE go.title = 'LAB4 bulk order 01'
    LIMIT 20000
)
INSERT INTO order_items (
    participation_id,
    product_id,
    quantity,
    price_per_unit,
    line_total
)
SELECT
    pp.participation_id,
    tp.product_id,
    ((series.n - 1) % 25 + 1)::DECIMAL(10,2) AS quantity,
    tp.price,
    (((series.n - 1) % 25 + 1) * tp.price)::DECIMAL(10,2) AS line_total
FROM generate_series(1, 20000) AS series(n)
JOIN participant_pool pp
    ON pp.rn = series.n
CROSS JOIN target_product tp;

-- UPDATE without additional LAB4 indexes.
EXPLAIN (ANALYZE, BUFFERS)
UPDATE order_items oi
SET
    quantity = oi.quantity + 1,
    line_total = (oi.quantity + 1) * oi.price_per_unit
FROM products pr
WHERE oi.product_id = pr.product_id
  AND pr.name = 'LAB4 benchmark item';

DELETE FROM order_items oi
USING products pr
WHERE oi.product_id = pr.product_id
  AND pr.name = 'LAB4 benchmark item';

CREATE INDEX lab4_idx_order_items_product_line_quantity
    ON order_items (product_id, line_total, quantity);

CREATE INDEX lab4_idx_order_items_line_total_desc
    ON order_items (line_total DESC, order_item_id)
    INCLUDE (participation_id, product_id, quantity, price_per_unit);

CREATE INDEX lab4_idx_order_items_product_line_desc
    ON order_items (product_id, line_total DESC, order_item_id)
    INCLUDE (participation_id, quantity);

CREATE INDEX lab4_idx_order_items_quantity
    ON order_items (quantity);

CREATE INDEX lab4_idx_order_items_participation_product
    ON order_items (participation_id, product_id)
    INCLUDE (line_total);

CREATE INDEX lab4_idx_order_items_product_participation
    ON order_items (product_id, participation_id)
    INCLUDE (line_total);

ANALYZE order_items;

-- INSERT with additional LAB4 indexes.
EXPLAIN (ANALYZE, BUFFERS)
WITH target_product AS (
    SELECT product_id, price
    FROM products
    WHERE name = 'LAB4 benchmark item'
    ORDER BY product_id
    LIMIT 1
),
participant_pool AS (
    SELECT
        p.participation_id,
        ROW_NUMBER() OVER (ORDER BY p.participation_id) AS rn
    FROM participations p
    JOIN group_orders go
        ON go.group_order_id = p.group_order_id
    WHERE go.title = 'LAB4 bulk order 01'
    LIMIT 20000
)
INSERT INTO order_items (
    participation_id,
    product_id,
    quantity,
    price_per_unit,
    line_total
)
SELECT
    pp.participation_id,
    tp.product_id,
    ((series.n - 1) % 25 + 1)::DECIMAL(10,2) AS quantity,
    tp.price,
    (((series.n - 1) % 25 + 1) * tp.price)::DECIMAL(10,2) AS line_total
FROM generate_series(1, 20000) AS series(n)
JOIN participant_pool pp
    ON pp.rn = series.n
CROSS JOIN target_product tp;

-- UPDATE with additional LAB4 indexes.
EXPLAIN (ANALYZE, BUFFERS)
UPDATE order_items oi
SET
    quantity = oi.quantity + 1,
    line_total = (oi.quantity + 1) * oi.price_per_unit
FROM products pr
WHERE oi.product_id = pr.product_id
  AND pr.name = 'LAB4 benchmark item';

DELETE FROM order_items oi
USING products pr
WHERE oi.product_id = pr.product_id
  AND pr.name = 'LAB4 benchmark item';

ANALYZE order_items;
