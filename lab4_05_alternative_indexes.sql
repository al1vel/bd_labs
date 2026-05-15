-- Lab 4. Alternative indexing strategies for the same query.
-- Compare product-only index versus product plus ordering key.

\timing on

DROP INDEX IF EXISTS lab4_idx_order_items_product_only;
DROP INDEX IF EXISTS lab4_idx_order_items_product_line_desc;
DROP INDEX IF EXISTS lab4_idx_order_items_product_line_quantity;
DROP INDEX IF EXISTS lab4_idx_order_items_line_total_desc;
DROP INDEX IF EXISTS lab4_idx_order_items_participation_product;
DROP INDEX IF EXISTS lab4_idx_order_items_product_participation;

ANALYZE order_items;

-- Baseline for this exact query.
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

-- Variant A: helps filtering by product_id, but still needs sorting.
CREATE INDEX lab4_idx_order_items_product_only
    ON order_items (product_id);

ANALYZE order_items;

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

DROP INDEX IF EXISTS lab4_idx_order_items_product_only;

-- Variant B: supports both filtering and ORDER BY/LIMIT.
CREATE INDEX lab4_idx_order_items_product_line_desc
    ON order_items (product_id, line_total DESC, order_item_id)
    INCLUDE (participation_id, quantity);

ANALYZE order_items;

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
