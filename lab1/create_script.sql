DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS participations CASCADE;
DROP TABLE IF EXISTS group_orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20)
);

CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    supplier_type VARCHAR(20) NOT NULL CHECK (supplier_type IN ('store', 'farmer'))
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    supplier_id INT NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    is_active BOOLEAN DEFAULT TRUE,

    CONSTRAINT fk_products_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id)
        ON DELETE CASCADE
);

CREATE TABLE group_orders (
    group_order_id SERIAL PRIMARY KEY,
    supplier_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'open',
    min_participants INT CHECK (min_participants >= 1),
    min_total_amount DECIMAL(10,2) CHECK (min_total_amount >= 0),

    CONSTRAINT fk_group_orders_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id)
        ON DELETE CASCADE
);

CREATE TABLE participations (
    participation_id SERIAL PRIMARY KEY,
    group_order_id INT NOT NULL,
    user_id INT NOT NULL,
    participant_status VARCHAR(20) DEFAULT 'joined',
    participation_role VARCHAR(20) NOT NULL DEFAULT 'participant'
        CHECK (participation_role IN ('participant', 'organizer')),

    CONSTRAINT fk_participations_order
        FOREIGN KEY (group_order_id)
        REFERENCES group_orders(group_order_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_participations_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT unique_participation
        UNIQUE (group_order_id, user_id)
);

CREATE UNIQUE INDEX unique_group_order_organizer
    ON participations(group_order_id)
    WHERE participation_role = 'organizer';

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    participation_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity DECIMAL(10,2) NOT NULL CHECK (quantity > 0),
    price_per_unit DECIMAL(10,2) NOT NULL CHECK (price_per_unit > 0),
    line_total DECIMAL(10,2) NOT NULL CHECK (line_total >= 0),

    CONSTRAINT fk_order_items_participation
        FOREIGN KEY (participation_id)
        REFERENCES participations(participation_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE
);
