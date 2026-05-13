INSERT INTO users (full_name, email, phone) VALUES
('Иван Иванов', 'ivan@example.com', '111111111'),
('Мария Петрова', 'maria@example.com', '222222222'),
('Алексей Смирнов', 'alex@example.com', '333333333'),
('Ольга Сидорова', 'olga@example.com', '444444444'),
('Дмитрий Кузнецов', 'dmitry@example.com', '555555555'),
('Анна Васильева', 'anna@example.com', '666666666'),
('Сергей Павлов', 'sergey@example.com', '777777777'),
('Елена Орлова', 'elena@example.com', '888888888'),
('Максим Волков', 'max@example.com', '999999999'),
('Наталья Фёдорова', 'natasha@example.com', '101010101');

INSERT INTO suppliers (name, supplier_type) VALUES
('Фермерское хозяйство "Зелёный луг"', 'farmer'),
('Магазин "Продукты для дома"', 'store'),
('Эко-ферма "Чистый продукт"', 'farmer');

INSERT INTO products (supplier_id, name, description, price, is_active) VALUES
(1, 'Яблоки', 'Свежие яблоки', 120.50, TRUE),
(1, 'Картофель', 'Домашний картофель', 60.00, TRUE),
(1, 'Морковь', 'Свежая морковь', 50.00, TRUE),

(2, 'Молоко', 'Молоко 1л', 90.00, TRUE),
(2, 'Хлеб', 'Белый хлеб', 45.00, TRUE),
(2, 'Сыр', 'Твёрдый сыр', 300.00, TRUE),

(3, 'Мёд', 'Натуральный мёд', 500.00, TRUE),
(3, 'Яйца', 'Домашние яйца', 150.00, TRUE),
(3, 'Масло', 'Сливочное масло', 200.00, TRUE),
(3, 'Творог', 'Домашний творог', 180.00, TRUE);

INSERT INTO group_orders (
    supplier_id,
    title,
    description,
    status,
    min_participants,
    min_total_amount
) VALUES
(1, 'Закупка овощей', 'Овощи с фермы', 'open', 3, 500.00),
(2, 'Продукты на неделю', 'Магазинные продукты', 'open', 2, 300.00),
(3, 'Эко продукты', 'Фермерская продукция', 'open', 4, 800.00),
(1, 'Картофель и морковь', 'Овощи оптом', 'open', 2, 200.00);

INSERT INTO participations (group_order_id, user_id, participant_status, participation_role) VALUES
-- Закупка 1
(1, 1, 'joined', 'organizer'),
(1, 2, 'joined', 'participant'),
(1, 3, 'joined', 'participant'),
(1, 4, 'joined', 'participant'),

-- Закупка 2
(2, 2, 'joined', 'organizer'),
(2, 5, 'joined', 'participant'),
(2, 6, 'joined', 'participant'),

-- Закупка 3
(3, 3, 'joined', 'organizer'),
(3, 7, 'joined', 'participant'),
(3, 8, 'joined', 'participant'),
(3, 9, 'joined', 'participant'),
(3, 10, 'joined', 'participant'),

-- Закупка 4
(4, 4, 'joined', 'organizer'),
(4, 1, 'joined', 'participant'),
(4, 6, 'joined', 'participant');

INSERT INTO order_items (
    participation_id,
    product_id,
    quantity,
    price_per_unit,
    line_total
) VALUES
-- Закупка 1
(1, 1, 2, 120.50, 241.00),
(1, 2, 3, 60.00, 180.00),
(2, 1, 1, 120.50, 120.50),
(3, 2, 5, 60.00, 300.00),
(4, 3, 2, 50.00, 100.00),

-- Закупка 2
(5, 4, 2, 90.00, 180.00),
(5, 5, 3, 45.00, 135.00),
(6, 6, 1, 300.00, 300.00),
(7, 4, 4, 90.00, 360.00),

-- Закупка 3
(8, 7, 1, 500.00, 500.00),
(9, 8, 2, 150.00, 300.00),
(10, 9, 1, 200.00, 200.00),
(11, 10, 3, 180.00, 540.00),
(12, 7, 2, 500.00, 1000.00),

-- Закупка 4
(13, 2, 4, 60.00, 240.00),
(14, 3, 3, 50.00, 150.00),
(15, 1, 1, 120.50, 120.50);
