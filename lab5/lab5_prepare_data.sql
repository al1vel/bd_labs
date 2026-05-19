INSERT INTO suppliers (name, supplier_type) VALUES
('LAB5 Farmer Cooperative', 'farmer'),
('LAB5 Local Store', 'store');

INSERT INTO users (full_name, email, phone) VALUES
('LAB5 Organizer', 'lab5.organizer@example.com', '+70000000001'),
('LAB5 Participant Anna', 'lab5.anna@example.com', '+70000000002'),
('LAB5 Participant Boris', 'lab5.boris@example.com', '+70000000003'),
('LAB5 Participant Vera', 'lab5.vera@example.com', '+70000000004');

INSERT INTO products (supplier_id, name, description, price, is_active)
SELECT supplier_id, 'LAB5 Potatoes', 'Potatoes from farmer for grouped order', 80.00, TRUE
FROM suppliers WHERE name = 'LAB5 Farmer Cooperative';

INSERT INTO products (supplier_id, name, description, price, is_active)
SELECT supplier_id, 'LAB5 Milk', 'Milk from farmer for grouped order', 120.00, TRUE
FROM suppliers WHERE name = 'LAB5 Farmer Cooperative';

INSERT INTO products (supplier_id, name, description, price, is_active)
SELECT supplier_id, 'LAB5 Cheese', 'Cheese from farmer for grouped order', 350.00, TRUE
FROM suppliers WHERE name = 'LAB5 Farmer Cooperative';

INSERT INTO group_orders (supplier_id, title, description, status, min_participants, min_total_amount)
SELECT supplier_id, 'LAB5 Farmer weekly order', 'Weekly grouped order from farmer', 'open', 3, 2000.00
FROM suppliers WHERE name = 'LAB5 Farmer Cooperative';

-- Organizer participation.
INSERT INTO participations (group_order_id, user_id, participant_status, participation_role)
SELECT go.group_order_id, u.user_id, 'joined', 'organizer'
FROM group_orders go
JOIN users u ON u.email = 'lab5.organizer@example.com'
WHERE go.title = 'LAB5 Farmer weekly order';

-- Initial participant and items for aggregation tests.
INSERT INTO participations (group_order_id, user_id, participant_status, participation_role)
SELECT go.group_order_id, u.user_id, 'joined', 'participant'
FROM group_orders go
JOIN users u ON u.email = 'lab5.anna@example.com'
WHERE go.title = 'LAB5 Farmer weekly order';

INSERT INTO order_items (participation_id, product_id, quantity, price_per_unit, line_total)
SELECT p.participation_id, pr.product_id, 5, pr.price, 5 * pr.price
FROM participations p
JOIN users u ON u.user_id = p.user_id
JOIN group_orders go ON go.group_order_id = p.group_order_id
JOIN products pr ON pr.name = 'LAB5 Potatoes'
WHERE u.email = 'lab5.anna@example.com'
  AND go.title = 'LAB5 Farmer weekly order';

INSERT INTO order_items (participation_id, product_id, quantity, price_per_unit, line_total)
SELECT p.participation_id, pr.product_id, 2, pr.price, 2 * pr.price
FROM participations p
JOIN users u ON u.user_id = p.user_id
JOIN group_orders go ON go.group_order_id = p.group_order_id
JOIN products pr ON pr.name = 'LAB5 Cheese'
WHERE u.email = 'lab5.anna@example.com'
  AND go.title = 'LAB5 Farmer weekly order';
