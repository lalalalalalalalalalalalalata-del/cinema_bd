-- Trigger tests. Use them after full restore.

-- 1. Проверка автоматического расчета цены билета.
BEGIN;
INSERT INTO tickets(session_id, seat_id, user_id, price, status, payment_method)
SELECT s.id, se.id, u.id, 0, 'booked', 'card'
FROM sessions s
JOIN seats se ON se.hall_id = s.hall_id
CROSS JOIN users u
WHERE NOT EXISTS (
    SELECT 1
    FROM tickets t
    WHERE t.session_id = s.id
      AND t.seat_id = se.id
      AND t.status IN ('booked', 'paid')
)
LIMIT 1;
SELECT * FROM tickets ORDER BY id DESC LIMIT 1;
ROLLBACK;

-- 2. Проверка запрета двойной продажи одного места.
-- Второй INSERT должен завершиться ошибкой, потому что место уже занято.
BEGIN;
WITH free_place AS (
    SELECT s.id AS session_id, se.id AS seat_id, u.id AS user_id
    FROM sessions s
    JOIN seats se ON se.hall_id = s.hall_id
    CROSS JOIN users u
    WHERE NOT EXISTS (
        SELECT 1 FROM tickets t
        WHERE t.session_id = s.id AND t.seat_id = se.id AND t.status IN ('booked', 'paid')
    )
    LIMIT 1
)
INSERT INTO tickets(session_id, seat_id, user_id, price, status, payment_method)
SELECT session_id, seat_id, user_id, 0, 'booked', 'card'
FROM free_place;
-- Повторить тот же INSERT вручную для демонстрации ошибки.
ROLLBACK;

-- 3. Проверка автоматического end_time у сеанса.
BEGIN;
INSERT INTO sessions(film_id, hall_id, start_time, end_time, base_price, status)
SELECT f.id, h.id, '2030-01-01 12:00:00', '2030-01-01 12:01:00', 500, 'scheduled'
FROM films f
CROSS JOIN halls h
LIMIT 1;
SELECT id, film_id, hall_id, start_time, end_time FROM sessions ORDER BY id DESC LIMIT 1;
ROLLBACK;
