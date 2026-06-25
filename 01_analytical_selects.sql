-- Analytical SELECT examples for project demonstration.

-- 1. Расписание сеансов с фильмами, залами и количеством проданных билетов.
SELECT
    s.id AS session_id,
    f.title AS film_title,
    h.name AS hall_name,
    s.start_time,
    s.end_time,
    s.base_price,
    COUNT(t.id) FILTER (WHERE t.status IN ('booked', 'paid')) AS active_tickets
FROM sessions s
JOIN films f ON f.id = s.film_id
JOIN halls h ON h.id = s.hall_id
LEFT JOIN tickets t ON t.session_id = s.id
GROUP BY s.id, f.title, h.name, s.start_time, s.end_time, s.base_price
ORDER BY s.start_time;

-- 2. Выручка по фильмам.
SELECT
    f.title,
    COUNT(t.id) AS tickets_count,
    SUM(t.price) AS revenue
FROM tickets t
JOIN sessions s ON s.id = t.session_id
JOIN films f ON f.id = s.film_id
WHERE t.status = 'paid'
GROUP BY f.title
ORDER BY revenue DESC NULLS LAST;

-- 3. Загруженность залов по сеансам.
SELECT
    s.id AS session_id,
    h.name AS hall_name,
    f.title AS film_title,
    COUNT(t.id) FILTER (WHERE t.status IN ('booked', 'paid')) AS occupied_seats,
    COUNT(se.id) AS total_seats,
    ROUND(
        COUNT(t.id) FILTER (WHERE t.status IN ('booked', 'paid'))::numeric / NULLIF(COUNT(se.id), 0) * 100,
        2
    ) AS occupancy_percent
FROM sessions s
JOIN halls h ON h.id = s.hall_id
JOIN films f ON f.id = s.film_id
JOIN seats se ON se.hall_id = h.id
LEFT JOIN tickets t ON t.session_id = s.id AND t.seat_id = se.id
GROUP BY s.id, h.name, f.title
ORDER BY occupancy_percent DESC;

-- 4. История изменения статусов билетов.
SELECT
    l.id,
    l.ticket_id,
    u.full_name,
    l.old_status,
    l.new_status,
    l.changed_at,
    l.changed_by
FROM ticket_status_log l
JOIN tickets t ON t.id = l.ticket_id
LEFT JOIN users u ON u.id = t.user_id
ORDER BY l.changed_at DESC;
