-- DML examples for demonstration. They are wrapped in transactions.

-- 1. Добавление нового пользователя.
BEGIN;
INSERT INTO users(full_name, email, phone, birth_date, password_hash)
VALUES ('Тестовый Пользователь', 'test.user@example.com', '+79990000000', '2002-05-10', 'demo_hash');
SELECT * FROM users WHERE email = 'test.user@example.com';
ROLLBACK;

-- 2. Обновление статуса билета. Должен сработать триггер логирования.
BEGIN;
UPDATE tickets
SET status = 'paid'
WHERE id = (SELECT id FROM tickets ORDER BY id LIMIT 1);
SELECT * FROM ticket_status_log ORDER BY changed_at DESC LIMIT 5;
ROLLBACK;

-- 3. Мягкое отключение фильма из афиши.
BEGIN;
UPDATE films
SET is_active = false
WHERE id = (SELECT id FROM films ORDER BY id LIMIT 1);
SELECT id, title, is_active FROM films ORDER BY id LIMIT 5;
ROLLBACK;
