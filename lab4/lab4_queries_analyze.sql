ANALYZE users;
ANALYZE group_orders;
ANALYZE participations;
ANALYZE order_items;

-- 1. Сложный фильтр. Запрос с несколькими условиями
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    oi.order_item_id,
    oi.participation_id,
    oi.product_id,
    oi.quantity,
    oi.line_total
FROM order_items oi
WHERE oi.product_id = (
        SELECT product_id
        FROM products
        WHERE name = 'LAB4 milk'
    )
  AND oi.line_total BETWEEN 900.00 AND 1800.00
  AND oi.quantity BETWEEN 10 AND 20
ORDER BY oi.line_total, oi.order_item_id
LIMIT 200;

-- 2. Сортировка с ограничением
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

-- 4. Текстовый поиск
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

-- 5. Запрос, включающий соединение двух или более таблиц
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
        SELECT product_id
        FROM products
        WHERE name = 'LAB4 potatoes'
    )
GROUP BY u.user_id, u.email
ORDER BY total_amount DESC
LIMIT 100;

-- 6. Негативный сценарий
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM order_items oi
WHERE (oi.quantity + 0) > 0;
