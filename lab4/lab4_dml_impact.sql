DROP INDEX IF EXISTS lab4_idx_order_items_product_line_quantity;
DROP INDEX IF EXISTS lab4_idx_order_items_line_total_desc;
DROP INDEX IF EXISTS lab4_idx_order_items_product_line_desc;
DROP INDEX IF EXISTS lab4_idx_order_items_product_only;
DROP INDEX IF EXISTS lab4_idx_order_items_quantity;
DROP INDEX IF EXISTS lab4_idx_order_items_participation_product;
DROP INDEX IF EXISTS lab4_idx_order_items_product_participation;

ANALYZE order_items;

-- INSERT без индексов
EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO order_items (
    participation_id,
    product_id,
    quantity,
    price_per_unit,
    line_total
)
SELECT
    1,
    1,
    10,
    100.00,
    1000.00
FROM generate_series(1, 20000);

-- UPDATE без индексов
EXPLAIN (ANALYZE, BUFFERS)
UPDATE order_items
SET
    quantity = quantity + 1,
    line_total = line_total + price_per_unit
WHERE order_item_id > (
    SELECT MAX(order_item_id) - 20000
    FROM order_items
);


DELETE FROM order_items
WHERE order_item_id > (
    SELECT MAX(order_item_id) - 20000
    FROM order_items
);

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


-- INSERT с индексами
EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO order_items (
    participation_id,
    product_id,
    quantity,
    price_per_unit,
    line_total
)
SELECT
    1,
    1,
    10,
    100.00,
    1000.00
FROM generate_series(1, 20000);

-- UPDATE с индексами
EXPLAIN (ANALYZE, BUFFERS)
UPDATE order_items
SET
    quantity = quantity + 1,
    line_total = line_total + price_per_unit
WHERE order_item_id > (
    SELECT MAX(order_item_id) - 20000
    FROM order_items
);