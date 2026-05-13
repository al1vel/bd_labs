CREATE OR REPLACE VIEW users_activity_summary AS
WITH created_orders AS (
    SELECT
        user_id,
        COUNT(DISTINCT group_order_id) AS created_orders_count
    FROM participations
    WHERE participation_role = 'organizer'
    GROUP BY user_id
),
participation_stats AS (
    SELECT
        p.user_id,
        COUNT(DISTINCT p.participation_id)
            FILTER (WHERE p.participation_role = 'participant') AS participations_count,
        SUM(oi.line_total) AS total_ordered_amount
    FROM participations p
    LEFT JOIN order_items oi
        ON p.participation_id = oi.participation_id
    GROUP BY p.user_id
)
SELECT
    u.user_id,
    u.full_name,
    u.email,
    COALESCE(co.created_orders_count, 0) AS created_orders_count,
    COALESCE(ps.participations_count, 0) AS participations_count,
    COALESCE(ps.total_ordered_amount, 0) AS total_ordered_amount
FROM users u
LEFT JOIN created_orders co
    ON u.user_id = co.user_id
LEFT JOIN participation_stats ps
    ON u.user_id = ps.user_id;

SELECT * FROM users_activity_summary;
