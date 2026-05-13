SELECT go.title, COUNT(p.participation_id) AS participants_count
FROM group_orders go
LEFT JOIN participations p
    ON go.group_order_id = p.group_order_id
    AND p.participation_role = 'participant'
GROUP BY go.title;
