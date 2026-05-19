SELECT go.title, SUM(oi.line_total) AS total_amount
FROM group_orders go
JOIN participations p ON go.group_order_id = p.group_order_id
JOIN order_items oi ON p.participation_id = oi.participation_id
GROUP BY go.title;