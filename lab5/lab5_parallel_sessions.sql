
-- Демонстрация блокировки
-- SESSION 1:
BEGIN;
SELECT product_id, name, price
FROM products
WHERE name = 'LAB5 Milk'
FOR UPDATE;
-- Do not commit yet. The row is locked.

-- SESSION 2:
BEGIN;
UPDATE products
SET price = price + 10
WHERE name = 'LAB5 Milk';
-- This query waits until SESSION 1 ends because SESSION 1 locked the row.

-- SESSION 1:
COMMIT;

-- SESSION 2:
COMMIT;
SELECT name, price FROM products WHERE name = 'LAB5 Milk';


-- B. READ COMMITTED
-- SESSION 1:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT status FROM group_orders WHERE title = 'LAB5 Farmer weekly order';

-- SESSION 2:
BEGIN;
UPDATE group_orders SET status = 'placed' WHERE title = 'LAB5 Farmer weekly order';
COMMIT;

-- SESSION 1:
SELECT status FROM group_orders WHERE title = 'LAB5 Farmer weekly order';
COMMIT;

-- Reset:
UPDATE group_orders SET status = 'open' WHERE title = 'LAB5 Farmer weekly order';


-- C. REPEATABLE READ
-- SESSION 1:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT status FROM group_orders WHERE title = 'LAB5 Farmer weekly order';

-- SESSION 2:
BEGIN;
UPDATE group_orders SET status = 'placed' WHERE title = 'LAB5 Farmer weekly order';
COMMIT;

-- SESSION 1:
SELECT status FROM group_orders WHERE title = 'LAB5 Farmer weekly order';
COMMIT;

-- Reset:
UPDATE group_orders SET status = 'open' WHERE title = 'LAB5 Farmer weekly order';


-- D. SERIALIZABLE
-- SESSION 1:
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT status FROM group_orders WHERE title = 'LAB5 Farmer weekly order';
UPDATE group_orders SET status = 'by_session_1' WHERE title = 'LAB5 Farmer weekly order';

-- SESSION 2:
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT status FROM group_orders WHERE title = 'LAB5 Farmer weekly order';
UPDATE group_orders SET status = 'by_session_2' WHERE title = 'LAB5 Farmer weekly order';

-- SESSION 1:
COMMIT;

-- SESSION 2:
ROLLBACK;

SELECT title, status FROM group_orders WHERE title = 'LAB5 Farmer weekly order';
