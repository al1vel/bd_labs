-- Сценарий 1. участник добавляется в закупку и выбирает продукты.

-- 1A. Успешная транзакция
BEGIN;

INSERT INTO participations (group_order_id, user_id, participant_status, participation_role)
SELECT go.group_order_id, u.user_id, 'joined', 'participant'
FROM group_orders go
JOIN users u ON u.email = 'lab5.boris@example.com'
WHERE go.title = 'LAB5 Farmer weekly order'
RETURNING participation_id;

INSERT INTO order_items (participation_id, product_id, quantity, price_per_unit, line_total)
SELECT p.participation_id, pr.product_id, 3, pr.price, 3 * pr.price
FROM participations p
JOIN users u ON u.user_id = p.user_id
JOIN group_orders go ON go.group_order_id = p.group_order_id
JOIN products pr ON pr.name = 'LAB5 Milk'
WHERE u.email = 'lab5.boris@example.com'
  AND go.title = 'LAB5 Farmer weekly order';

COMMIT;

SELECT u.email, p.participant_status, p.participation_role, pr.name, oi.quantity, oi.line_total
FROM participations p
JOIN users u ON u.user_id = p.user_id
LEFT JOIN order_items oi ON oi.participation_id = p.participation_id
LEFT JOIN products pr ON pr.product_id = oi.product_id
WHERE u.email = 'lab5.boris@example.com';

-- 1B. Ошибка (quantity > 0) и полный откат.
BEGIN;

INSERT INTO participations (group_order_id, user_id, participant_status, participation_role)
SELECT go.group_order_id, u.user_id, 'joined', 'participant'
FROM group_orders go
JOIN users u ON u.email = 'lab5.vera@example.com'
WHERE go.title = 'LAB5 Farmer weekly order';

INSERT INTO order_items (participation_id, product_id, quantity, price_per_unit, line_total)
SELECT p.participation_id, pr.product_id, -1, pr.price, -1 * pr.price
FROM participations p
JOIN users u ON u.user_id = p.user_id
JOIN group_orders go ON go.group_order_id = p.group_order_id
JOIN products pr ON pr.name = 'LAB5 Milk'
WHERE u.email = 'lab5.vera@example.com'
  AND go.title = 'LAB5 Farmer weekly order';

ROLLBACK;

SELECT *
FROM participations p
JOIN users u ON u.user_id = p.user_id
WHERE u.email = 'lab5.vera@example.com';

-- 1C. SAVEPOINT. Участник остается, невалидный товар отменяется, затем добавляется валидный.
BEGIN;

INSERT INTO participations (group_order_id, user_id, participant_status, participation_role)
SELECT go.group_order_id, u.user_id, 'joined', 'participant'
FROM group_orders go
JOIN users u ON u.email = 'lab5.vera@example.com'
WHERE go.title = 'LAB5 Farmer weekly order';

SAVEPOINT before_bad_item;

INSERT INTO order_items (participation_id, product_id, quantity, price_per_unit, line_total)
SELECT p.participation_id, pr.product_id, 0, pr.price, 0
FROM participations p
JOIN users u ON u.user_id = p.user_id
JOIN group_orders go ON go.group_order_id = p.group_order_id
JOIN products pr ON pr.name = 'LAB5 Milk'
WHERE u.email = 'lab5.vera@example.com'
  AND go.title = 'LAB5 Farmer weekly order';

ROLLBACK TO SAVEPOINT before_bad_item;

INSERT INTO order_items (participation_id, product_id, quantity, price_per_unit, line_total)
SELECT p.participation_id, pr.product_id, 4, pr.price, 4 * pr.price
FROM participations p
JOIN users u ON u.user_id = p.user_id
JOIN group_orders go ON go.group_order_id = p.group_order_id
JOIN products pr ON pr.name = 'LAB5 Milk'
WHERE u.email = 'lab5.vera@example.com'
  AND go.title = 'LAB5 Farmer weekly order';

COMMIT;


-- Сценарий 2. Организатор оформляет заказ у поставщика.

-- 2A. успешно
BEGIN;

UPDATE group_orders
SET status = 'placed'
WHERE title = 'LAB5 Farmer weekly order'
  AND status = 'open';

UPDATE participations
SET participant_status = 'confirmed'
WHERE group_order_id = (
    SELECT group_order_id FROM group_orders WHERE title = 'LAB5 Farmer weekly order'
)
  AND participant_status = 'joined';

COMMIT;

SELECT go.title, go.status, u.email, p.participant_status
FROM group_orders go
JOIN participations p ON p.group_order_id = go.group_order_id
JOIN users u ON u.user_id = p.user_id
WHERE go.title = 'LAB5 Farmer weekly order'
ORDER BY u.email;

-- Reset
UPDATE group_orders SET status = 'open' WHERE title = 'LAB5 Farmer weekly order';
UPDATE participations SET participant_status = 'joined'
WHERE group_order_id = (SELECT group_order_id FROM group_orders WHERE title = 'LAB5 Farmer weekly order');

-- 2B. Один из участников ливает во время транзакции - полный откат

BEGIN;

UPDATE group_orders
SET status = 'placed'
WHERE title = 'LAB5 Farmer weekly order'
  AND status = 'open';

UPDATE participations p
SET participant_status = 'cancelled'
FROM users u, group_orders go
WHERE p.user_id = u.user_id
  AND p.group_order_id = go.group_order_id
  AND u.email = 'lab5.vera@example.com'
  AND go.title = 'LAB5 Farmer weekly order';

UPDATE participations
SET participant_status = 'confirmed'
WHERE group_order_id = (
    SELECT group_order_id
    FROM group_orders
    WHERE title = 'LAB5 Farmer weekly order'
)
  AND participation_role = 'participant'
  AND participant_status = 'joined';

DO $$
DECLARE
    confirmed_count INT;
    required_count INT;
BEGIN
    SELECT COUNT(*), MAX(go.min_participants)
    INTO confirmed_count, required_count
    FROM group_orders go
    JOIN participations p ON p.group_order_id = go.group_order_id
    WHERE go.title = 'LAB5 Farmer weekly order'
      AND p.participation_role = 'participant'
      AND p.participant_status = 'confirmed';

    IF confirmed_count < required_count THEN
        RAISE EXCEPTION
            'Cannot place order: confirmed participants = %, required = %',
            confirmed_count, required_count;
    END IF;
END $$;

ROLLBACK;

SELECT go.title, go.status, u.email, p.participant_status
FROM group_orders go
JOIN participations p ON p.group_order_id = go.group_order_id
JOIN users u ON u.user_id = p.user_id
WHERE go.title = 'LAB5 Farmer weekly order'
ORDER BY u.email;

-- 2C. то же самое но с SAVEPOINT

BEGIN;

UPDATE group_orders
SET status = 'placed'
WHERE title = 'LAB5 Farmer weekly order'
  AND status = 'open';

SAVEPOINT before_participant_cancellation;

UPDATE participations p
SET participant_status = 'cancelled'
FROM users u, group_orders go
WHERE p.user_id = u.user_id
  AND p.group_order_id = go.group_order_id
  AND u.email = 'lab5.vera@example.com'
  AND go.title = 'LAB5 Farmer weekly order';

UPDATE participations
SET participant_status = 'confirmed'
WHERE group_order_id = (
    SELECT group_order_id
    FROM group_orders
    WHERE title = 'LAB5 Farmer weekly order'
)
  AND participation_role = 'participant'
  AND participant_status = 'joined';


DO $$
DECLARE
    confirmed_count INT;
    required_count INT;
BEGIN
    SELECT COUNT(*), MAX(go.min_participants)
    INTO confirmed_count, required_count
    FROM group_orders go
    JOIN participations p ON p.group_order_id = go.group_order_id
    WHERE go.title = 'LAB5 Farmer weekly order'
      AND p.participation_role = 'participant'
      AND p.participant_status = 'confirmed';

    IF confirmed_count < required_count THEN
        RAISE EXCEPTION
            'Cannot place order: confirmed participants = %, required = %',
            confirmed_count, required_count;
    END IF;
END $$;

ROLLBACK TO SAVEPOINT before_participant_cancellation;

UPDATE participations
SET participant_status = 'confirmed'
WHERE group_order_id = (
    SELECT group_order_id
    FROM group_orders
    WHERE title = 'LAB5 Farmer weekly order'
)
  AND participation_role = 'participant'
  AND participant_status = 'joined';

COMMIT;

-- результат.
SELECT go.title, go.status, u.email, p.participant_status
FROM group_orders go
JOIN participations p ON p.group_order_id = go.group_order_id
JOIN users u ON u.user_id = p.user_id
WHERE go.title = 'LAB5 Farmer weekly order'
ORDER BY u.email;


-- Сценарий 3. Участник покидает закупку.

-- 3A. успешно
BEGIN;

DELETE FROM order_items
WHERE participation_id = (
    SELECT p.participation_id
    FROM participations p
    JOIN users u ON u.user_id = p.user_id
    JOIN group_orders go ON go.group_order_id = p.group_order_id
    WHERE u.email = 'lab5.boris@example.com'
      AND go.title = 'LAB5 Farmer weekly order'
);

UPDATE participations p
SET participant_status = 'cancelled'
FROM users u, group_orders go
WHERE p.user_id = u.user_id
  AND p.group_order_id = go.group_order_id
  AND u.email = 'lab5.boris@example.com'
  AND go.title = 'LAB5 Farmer weekly order';

UPDATE group_orders
SET status = 'open'
WHERE title = 'LAB5 Farmer weekly order';

COMMIT;

-- 3B. Пользователь пытается покинуть оформленный заказ - полный откат.

BEGIN;

UPDATE group_orders
SET status = 'placed'
WHERE title = 'LAB5 Farmer weekly order';

DELETE FROM order_items
WHERE participation_id = (
    SELECT p.participation_id
    FROM participations p
    JOIN users u ON u.user_id = p.user_id
    JOIN group_orders go ON go.group_order_id = p.group_order_id
    WHERE u.email = 'lab5.vera@example.com'
      AND go.title = 'LAB5 Farmer weekly order'
);

UPDATE participations p
SET participant_status = 'cancelled'
FROM users u, group_orders go
WHERE p.user_id = u.user_id
  AND p.group_order_id = go.group_order_id
  AND u.email = 'lab5.vera@example.com'
  AND go.title = 'LAB5 Farmer weekly order';

DO $$
DECLARE
    order_status TEXT;
BEGIN
    SELECT status
    INTO order_status
    FROM group_orders
    WHERE title = 'LAB5 Farmer weekly order';

    IF order_status <> 'open' THEN
        RAISE EXCEPTION
            'Participant cannot leave the order because order status is %',
            order_status;
    END IF;
END $$;

ROLLBACK;

-- Check
SELECT go.title, go.status, u.email, p.participant_status
FROM group_orders go
JOIN participations p ON p.group_order_id = go.group_order_id
JOIN users u ON u.user_id = p.user_id
WHERE go.title = 'LAB5 Farmer weekly order'
ORDER BY u.email;


-- 3C. SAVEPOINT

BEGIN;

UPDATE group_orders
SET status = 'open'
WHERE title = 'LAB5 Farmer weekly order';

DELETE FROM order_items
WHERE participation_id = (
    SELECT p.participation_id
    FROM participations p
    JOIN users u ON u.user_id = p.user_id
    JOIN group_orders go ON go.group_order_id = p.group_order_id
    WHERE u.email = 'lab5.boris@example.com'
      AND go.title = 'LAB5 Farmer weekly order'
);

UPDATE participations p
SET participant_status = 'cancelled'
FROM users u, group_orders go
WHERE p.user_id = u.user_id
  AND p.group_order_id = go.group_order_id
  AND u.email = 'lab5.boris@example.com'
  AND go.title = 'LAB5 Farmer weekly order';


SAVEPOINT before_wrong_order_cancellation;

-- заказ случайно отменился
UPDATE group_orders
SET status = 'cancelled'
WHERE title = 'LAB5 Farmer weekly order';

ROLLBACK TO SAVEPOINT before_wrong_order_cancellation;

UPDATE group_orders
SET status = 'open'
WHERE title = 'LAB5 Farmer weekly order';

COMMIT;

-- Check
SELECT go.title, go.status, u.email, p.participant_status
FROM group_orders go
JOIN participations p ON p.group_order_id = go.group_order_id
JOIN users u ON u.user_id = p.user_id
WHERE go.title = 'LAB5 Farmer weekly order'
ORDER BY u.email;
