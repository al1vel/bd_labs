CREATE OR REPLACE VIEW group_orders_summary AS
SELECT
    go.group_order_id,
    go.title,
    go.status,
    u.full_name AS organizer_name,
    s.name AS supplier_name,
    COUNT(DISTINCT p.participation_id)
        FILTER (WHERE p.participation_role = 'participant') AS participants_count,
    SUM(oi.line_total) AS total_amount
FROM group_orders go
LEFT JOIN participations organizer_p
    ON go.group_order_id = organizer_p.group_order_id
    AND organizer_p.participation_role = 'organizer'
LEFT JOIN users u
    ON organizer_p.user_id = u.user_id
JOIN suppliers s
    ON go.supplier_id = s.supplier_id
LEFT JOIN participations p
    ON go.group_order_id = p.group_order_id
LEFT JOIN order_items oi
    ON p.participation_id = oi.participation_id
GROUP BY
    go.group_order_id,
    go.title,
    go.status,
    u.full_name,
    s.name;

SELECT * FROM group_orders_summary;
