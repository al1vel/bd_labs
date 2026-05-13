DROP TABLE IF EXISTS group_order_status_audit CASCADE;

CREATE TABLE IF NOT EXISTS group_order_status_audit (
    audit_id SERIAL PRIMARY KEY,
    group_order_id INT NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_group_order_status_audit_order
        FOREIGN KEY (group_order_id)
        REFERENCES group_orders(group_order_id)
        ON DELETE CASCADE
);

CREATE OR REPLACE FUNCTION get_group_order_total(p_group_order_id INT)
RETURNS DECIMAL(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total DECIMAL(10,2);
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM group_orders
        WHERE group_order_id = p_group_order_id
    ) THEN
        RAISE EXCEPTION 'Group order with id % does not exist', p_group_order_id;
    END IF;

    SELECT COALESCE(SUM(oi.line_total), 0)
    INTO v_total
    FROM participations p
    JOIN order_items oi
        ON p.participation_id = oi.participation_id
    WHERE p.group_order_id = p_group_order_id;

    RETURN v_total;
END;
$$;

CREATE OR REPLACE FUNCTION is_group_order_ready(p_group_order_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_min_participants INT;
    v_min_total_amount DECIMAL(10,2);
    v_participants_count INT;
    v_total_amount DECIMAL(10,2);
BEGIN
    SELECT min_participants, min_total_amount
    INTO v_min_participants, v_min_total_amount
    FROM group_orders
    WHERE group_order_id = p_group_order_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Group order with id % does not exist', p_group_order_id;
    END IF;

    SELECT COUNT(*)
    INTO v_participants_count
    FROM participations
    WHERE group_order_id = p_group_order_id
      AND participation_role = 'participant';

    v_total_amount := get_group_order_total(p_group_order_id);

    RETURN
        v_participants_count >= v_min_participants
        AND
        v_total_amount >= v_min_total_amount;
END;
$$;

CREATE OR REPLACE PROCEDURE join_group_order(
    p_group_order_id INT,
    p_user_id INT,
    p_participation_role VARCHAR(20) DEFAULT 'participant'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_status VARCHAR(20);
BEGIN
    SELECT status
    INTO v_order_status
    FROM group_orders
    WHERE group_order_id = p_group_order_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cannot join: group order with id % does not exist', p_group_order_id;
    END IF;

    IF v_order_status <> 'open' THEN
        RAISE EXCEPTION 'Cannot join group order % because its status is %', p_group_order_id, v_order_status;
    END IF;

    INSERT INTO participations (
        group_order_id,
        user_id,
        participant_status,
        participation_role
    )
    VALUES (
        p_group_order_id,
        p_user_id,
        'joined',
        p_participation_role
    );
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Cannot join: user % already participates in group order % or the order already has an organizer',
            p_user_id,
            p_group_order_id;
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Cannot join: user % or group order % does not exist',
            p_user_id,
            p_group_order_id;
    WHEN check_violation THEN
        RAISE EXCEPTION 'Cannot join: role must be participant or organizer';
END;
$$;

CREATE OR REPLACE PROCEDURE add_order_item(
    p_participation_id INT,
    p_product_id INT,
    p_quantity DECIMAL(10,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO order_items (
        participation_id,
        product_id,
        quantity,
        price_per_unit,
        line_total
    )
    VALUES (
        p_participation_id,
        p_product_id,
        p_quantity,
        1,
        1
    );
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Cannot add item: participation % or product % does not exist',
            p_participation_id,
            p_product_id;
    WHEN check_violation THEN
        RAISE EXCEPTION 'Cannot add item: quantity must be positive';
END;
$$;

CREATE OR REPLACE FUNCTION check_participation_rules()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_status VARCHAR(20);
BEGIN
    SELECT status
    INTO v_order_status
    FROM group_orders
    WHERE group_order_id = NEW.group_order_id;

    IF v_order_status IS NULL THEN
        RAISE EXCEPTION 'Cannot add participation: group order % does not exist', NEW.group_order_id;
    END IF;

    IF v_order_status <> 'open' THEN
        RAISE EXCEPTION 'Cannot add participation to group order % with status %',
            NEW.group_order_id,
            v_order_status;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_participation_rules ON participations;

CREATE TRIGGER trg_check_participation_rules
BEFORE INSERT OR UPDATE ON participations
FOR EACH ROW
EXECUTE FUNCTION check_participation_rules();

CREATE OR REPLACE FUNCTION prepare_order_item()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_supplier_id INT;
    v_product_price DECIMAL(10,2);
    v_product_is_active BOOLEAN;
    v_order_supplier_id INT;
    v_order_status VARCHAR(20);
BEGIN
    SELECT pr.supplier_id, pr.price, pr.is_active
    INTO v_product_supplier_id, v_product_price, v_product_is_active
    FROM products pr
    WHERE pr.product_id = NEW.product_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cannot add item: product % does not exist', NEW.product_id;
    END IF;

    SELECT go.supplier_id, go.status
    INTO v_order_supplier_id, v_order_status
    FROM participations p
    JOIN group_orders go
        ON p.group_order_id = go.group_order_id
    WHERE p.participation_id = NEW.participation_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cannot add item: participation % does not exist', NEW.participation_id;
    END IF;

    IF v_order_status <> 'open' THEN
        RAISE EXCEPTION 'Cannot add item: group order status is %', v_order_status;
    END IF;

    IF NOT v_product_is_active THEN
        RAISE EXCEPTION 'Cannot add item: product % is inactive', NEW.product_id;
    END IF;

    IF v_product_supplier_id <> v_order_supplier_id THEN
        RAISE EXCEPTION 'Cannot add item: product % belongs to another supplier', NEW.product_id;
    END IF;

    NEW.price_per_unit := v_product_price;
    NEW.line_total := NEW.quantity * v_product_price;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prepare_order_item ON order_items;

CREATE TRIGGER trg_prepare_order_item
BEFORE INSERT OR UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION prepare_order_item();

CREATE OR REPLACE FUNCTION audit_group_order_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO group_order_status_audit (
            group_order_id,
            old_status,
            new_status
        )
        VALUES (
            NEW.group_order_id,
            OLD.status,
            NEW.status
        );
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_group_order_status ON group_orders;

CREATE TRIGGER trg_audit_group_order_status
AFTER UPDATE OF status ON group_orders
FOR EACH ROW
EXECUTE FUNCTION audit_group_order_status();

DO $$
DECLARE
    v_participation_id INT;
BEGIN
    CALL join_group_order(1, 5, 'participant');

    SELECT participation_id
    INTO v_participation_id
    FROM participations
    WHERE group_order_id = 1
      AND user_id = 5;

    CALL add_order_item(v_participation_id, 1, 2);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Demo join/add item failed: %', SQLERRM;
END;
$$;

SELECT get_group_order_total(1) AS group_order_1_total;
SELECT is_group_order_ready(1) AS group_order_1_is_ready;

UPDATE group_orders
SET status = 'completed'
WHERE group_order_id = 1;

SELECT *
FROM group_order_status_audit
WHERE group_order_id = 1;

DO $$
BEGIN
    CALL join_group_order(1, 6, 'participant');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Expected error: %', SQLERRM;
END;
$$;

DO $$
BEGIN
    CALL join_group_order(2, 2, 'participant');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Expected error: %', SQLERRM;
END;
$$;

DO $$
BEGIN
    CALL add_order_item(5, 1, 1);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Expected error: %', SQLERRM;
END;
$$;
