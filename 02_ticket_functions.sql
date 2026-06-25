-- Functions for ticket logic
-- Cinema database project. Generated from the provided PostgreSQL dump.
-- Run from repository root with: psql -d cinema_db -f scripts/restore_split.sql

CREATE FUNCTION public.fn_check_seat_availability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_session_hall_id INTEGER;
    v_seat_hall_id INTEGER;
BEGIN
    SELECT hall_id
      INTO v_session_hall_id
      FROM sessions
     WHERE id = NEW.session_id;

    SELECT hall_id
      INTO v_seat_hall_id
      FROM seats
     WHERE id = NEW.seat_id;

    IF v_session_hall_id IS NULL THEN
        RAISE EXCEPTION 'Session % not found', NEW.session_id;
    END IF;

    IF v_seat_hall_id IS NULL THEN
        RAISE EXCEPTION 'Seat % not found', NEW.seat_id;
    END IF;

    IF v_session_hall_id <> v_seat_hall_id THEN
        RAISE EXCEPTION 'Seat % does not belong to hall %', NEW.seat_id, v_session_hall_id;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM tickets t
         WHERE t.session_id = NEW.session_id
           AND t.seat_id = NEW.seat_id
           AND t.status IN ('booked', 'paid')
    ) THEN
        RAISE EXCEPTION 'Seat % is already occupied for session %', NEW.seat_id, NEW.session_id;
    END IF;

    RETURN NEW;
END;
$$;


CREATE FUNCTION public.fn_calculate_ticket_price() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_session_start TIMESTAMP;
    v_base_price NUMERIC(10,2);
    v_user_birth DATE;
    v_user_age INTEGER;
    v_seat_type VARCHAR(20);
    v_final_price NUMERIC(10,2);
BEGIN
    SELECT s.start_time, s.base_price
      INTO v_session_start, v_base_price
      FROM sessions s
     WHERE s.id = NEW.session_id;

    IF v_session_start IS NULL THEN
        RAISE EXCEPTION 'Session % not found', NEW.session_id;
    END IF;

    SELECT seat_type
      INTO v_seat_type
      FROM seats
     WHERE id = NEW.seat_id;

    v_final_price := v_base_price;

    IF EXTRACT(HOUR FROM v_session_start) < 12 THEN
        v_final_price := v_final_price * 0.8;
    END IF;

    IF v_seat_type = 'vip' THEN
        v_final_price := v_final_price * 1.25;
    ELSIF v_seat_type = 'accessible' THEN
        v_final_price := v_final_price * 0.95;
    END IF;

    IF NEW.user_id IS NOT NULL THEN
        SELECT birth_date
          INTO v_user_birth
          FROM users
         WHERE id = NEW.user_id;

        IF v_user_birth IS NOT NULL THEN
            v_user_age := EXTRACT(YEAR FROM AGE(v_session_start, v_user_birth));

            IF v_user_age BETWEEN 18 AND 25 THEN
                v_final_price := v_final_price * 0.9;
            ELSIF v_user_age >= 60 THEN
                v_final_price := v_final_price * 0.7;
            END IF;
        END IF;
    END IF;

    NEW.price := ROUND(v_final_price, 2);
    RETURN NEW;
END;
$$;


CREATE FUNCTION public.fn_block_late_ticket_cancellation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_session_start TIMESTAMP;
BEGIN
    IF NEW.status IN ('cancelled', 'refunded')
       AND OLD.status IN ('booked', 'paid') THEN

        SELECT s.start_time
          INTO v_session_start
          FROM sessions s
         WHERE s.id = NEW.session_id;

        IF v_session_start <= NOW() THEN
            RAISE EXCEPTION 'Ticket cannot be cancelled after the session has started';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


CREATE FUNCTION public.fn_log_ticket_status_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO ticket_status_log(ticket_id, old_status, new_status, changed_at, changed_by)
        VALUES (OLD.id, OLD.status, NEW.status, NOW(), CURRENT_USER);
    END IF;

    RETURN NEW;
END;
$$;
