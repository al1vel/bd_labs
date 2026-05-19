CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS lab4_idx_order_items_product_line_quantity
    ON order_items (product_id, line_total, quantity);

CREATE INDEX IF NOT EXISTS lab4_idx_order_items_line_total_desc
    ON order_items (line_total DESC, order_item_id)
    INCLUDE (participation_id, product_id, quantity, price_per_unit);

CREATE INDEX IF NOT EXISTS lab4_idx_order_items_product_line_desc
    ON order_items (product_id, line_total DESC, order_item_id)
    INCLUDE (participation_id, quantity);

CREATE INDEX IF NOT EXISTS lab4_idx_users_full_name_pattern
    ON users (full_name text_pattern_ops);

CREATE INDEX IF NOT EXISTS lab4_idx_users_full_name_trgm
    ON users USING gin (full_name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS lab4_idx_users_email_trgm
    ON users USING gin (email gin_trgm_ops);

CREATE INDEX IF NOT EXISTS lab4_idx_group_orders_title
    ON group_orders (title);

CREATE INDEX IF NOT EXISTS lab4_idx_participations_order_cover
    ON participations (group_order_id, participation_id, user_id);

CREATE INDEX IF NOT EXISTS lab4_idx_order_items_participation_product
    ON order_items (participation_id, product_id)
    INCLUDE (line_total);

CREATE INDEX IF NOT EXISTS lab4_idx_order_items_product_participation
    ON order_items (product_id, participation_id)
    INCLUDE (line_total);

CREATE INDEX IF NOT EXISTS lab4_idx_order_items_quantity
    ON order_items (quantity);
