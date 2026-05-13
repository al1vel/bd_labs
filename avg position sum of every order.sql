SELECT go.title, AVG(oi.line_total) AS avg_item_value
FROM group_orders go
JOIN participations p ON go.group_order_id = p.group_order_id
JOIN order_items oi ON p.participation_id = oi.participation_id
GROUP BY go.title;