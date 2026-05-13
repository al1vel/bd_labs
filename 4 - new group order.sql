INSERT INTO group_orders (
    supplier_id,
    title,
    description,
    status,
    min_participants,
    min_total_amount
)
VALUES (
    1,
    'Закупка фруктов',
    'Фрукты с фермы',
    'open',
    3,
    400.00
);

INSERT INTO participations (group_order_id, user_id, participant_status, participation_role)
VALUES (currval('group_orders_group_order_id_seq'), 1, 'joined', 'organizer');
