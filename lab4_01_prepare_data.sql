-- Lab 4. Data preparation for indexing experiments.
-- Run after create_script.sql and fill_tables.sql.
-- The script adds LAB4-marked data only and leaves existing rows intact.

\timing on

INSERT INTO suppliers (name, supplier_type)
SELECT 'LAB4 cooperative supplier', 'farmer'
WHERE NOT EXISTS (
    SELECT 1
    FROM suppliers
    WHERE name = 'LAB4 cooperative supplier'
);

INSERT INTO products (supplier_id, name, description, price, is_active)
SELECT s.supplier_id, v.name, v.description, v.price, TRUE
FROM suppliers s
CROSS JOIN (
    VALUES
        ('LAB4 apples', 'LAB4 seasonal apples for indexing tests', 120.50::DECIMAL(10,2)),
        ('LAB4 potatoes', 'LAB4 bulk potatoes for indexing tests', 60.00::DECIMAL(10,2)),
        ('LAB4 milk', 'LAB4 dairy product for indexing tests', 90.00::DECIMAL(10,2)),
        ('LAB4 cheese', 'LAB4 cheese product for indexing tests', 300.00::DECIMAL(10,2)),
        ('LAB4 benchmark item', 'LAB4 product used for insert and update benchmarks', 175.00::DECIMAL(10,2))
) AS v(name, description, price)
WHERE s.name = 'LAB4 cooperative supplier'
  AND NOT EXISTS (
      SELECT 1
      FROM products p
      WHERE p.supplier_id = s.supplier_id
        AND p.name = v.name
  );

INSERT INTO group_orders (
    supplier_id,
    title,
    description,
    status,
    min_participants,
    min_total_amount
)
SELECT
    s.supplier_id,
    'LAB4 bulk order 01',
    'LAB4 generated order with one million items',
    'open',
    1000,
    1000000.00
FROM suppliers s
WHERE s.name = 'LAB4 cooperative supplier'
  AND NOT EXISTS (
      SELECT 1
      FROM group_orders go
      WHERE go.title = 'LAB4 bulk order 01'
  );

-- Text-search scenarios use this million-row table.
INSERT INTO users (full_name, email, phone)
SELECT
    'Lab4 Buyer ' || LPAD(series.n::TEXT, 7, '0') AS full_name,
    'lab4_user_' || LPAD(series.n::TEXT, 7, '0') || '@lab4.example.com' AS email,
    LPAD((7000000000 + series.n)::TEXT, 11, '0') AS phone
FROM generate_series(1, 1000000) AS series(n)
ON CONFLICT (email) DO NOTHING;

INSERT INTO participations (
    group_order_id,
    user_id,
    participant_status,
    participation_role
)
SELECT
    go.group_order_id,
    u.user_id,
    'joined',
    CASE WHEN numbered.rn = 1 THEN 'organizer' ELSE 'participant' END
FROM group_orders go
JOIN (
    SELECT
        user_id,
        ROW_NUMBER() OVER (ORDER BY user_id) AS rn
    FROM users
    WHERE email LIKE 'lab4_user_%@lab4.example.com'
    ORDER BY user_id
    LIMIT 20000
) AS numbered
    ON TRUE
JOIN users u
    ON u.user_id = numbered.user_id
WHERE go.title = 'LAB4 bulk order 01'
ON CONFLICT DO NOTHING;

-- The main indexable fact table. Insert only if LAB4 order_items are absent.
WITH product_pool AS (
    SELECT
        product_id,
        price,
        ROW_NUMBER() OVER (ORDER BY product_id) AS rn
    FROM products
    WHERE name IN ('LAB4 apples', 'LAB4 potatoes', 'LAB4 milk', 'LAB4 cheese')
),
participant_pool AS (
    SELECT
        p.participation_id,
        ROW_NUMBER() OVER (ORDER BY p.participation_id) AS rn
    FROM participations p
    JOIN group_orders go
        ON go.group_order_id = p.group_order_id
    WHERE go.title = 'LAB4 bulk order 01'
),
pool_sizes AS (
    SELECT
        (SELECT COUNT(*) FROM product_pool) AS product_count,
        (SELECT COUNT(*) FROM participant_pool) AS participant_count
),
generated AS (
    SELECT
        series.n,
        ((series.n - 1) % ps.product_count) + 1 AS product_rn,
        ((series.n - 1) % ps.participant_count) + 1 AS participant_rn,
        ((series.n - 1) % 50) + 1 AS quantity
    FROM generate_series(1, 1000000) AS series(n)
    CROSS JOIN pool_sizes ps
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
    pr.product_id,
    g.quantity::DECIMAL(10,2),
    pr.price,
    (g.quantity * pr.price)::DECIMAL(10,2)
FROM generated g
JOIN participant_pool pp
    ON pp.rn = g.participant_rn
JOIN product_pool pr
    ON pr.rn = g.product_rn
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    JOIN participations p
        ON p.participation_id = oi.participation_id
    JOIN group_orders go
        ON go.group_order_id = p.group_order_id
    WHERE go.title = 'LAB4 bulk order 01'
    LIMIT 1
);

ANALYZE users;
ANALYZE suppliers;
ANALYZE products;
ANALYZE group_orders;
ANALYZE participations;
ANALYZE order_items;

SELECT
    'users' AS table_name,
    COUNT(*) AS lab4_rows
FROM users
WHERE email LIKE 'lab4_user_%@lab4.example.com'
UNION ALL
SELECT
    'order_items',
    COUNT(*)
FROM order_items oi
JOIN participations p
    ON p.participation_id = oi.participation_id
JOIN group_orders go
    ON go.group_order_id = p.group_order_id
WHERE go.title = 'LAB4 bulk order 01';
