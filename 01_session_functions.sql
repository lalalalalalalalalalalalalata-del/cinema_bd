-- Functions for halls and sessions
-- Cinema database project. Generated from the provided PostgreSQL dump.
-- Run from repository root with: psql -d cinema_db -f scripts/restore_split.sql

CREATE FUNCTION public.fn_generate_seats_for_hall(p_hall_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_rows INTEGER;
    v_seats_per_row INTEGER;
    v_hall_type VARCHAR(20);
    r INTEGER;
    s INTEGER;
BEGIN
    SELECT rows_count, seats_per_row, hall_type
      INTO v_rows, v_seats_per_row, v_hall_type
      FROM halls
     WHERE id = p_hall_id;

    IF v_rows IS NULL THEN
        RAISE EXCEPTION 'Hall % not found', p_hall_id;
    END IF;

    FOR r IN 1..v_rows LOOP
        FOR s IN 1..v_seats_per_row LOOP
            INSERT INTO seats(hall_id, row_number, seat_number, seat_type)
            VALUES (
                p_hall_id,
                r,
                s,
                CASE
                    WHEN r = 1 AND s IN (1, 2) THEN 'accessible'
                    WHEN v_hall_type = 'vip' AND r <= 2 THEN 'vip'
                    ELSE 'standard'
                END
            );
        END LOOP;
    END LOOP;
END;
$$;


CREATE FUNCTION public.fn_set_session_end_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_duration INTEGER;
BEGIN
    SELECT duration_minutes
      INTO v_duration
      FROM films
     WHERE id = NEW.film_id;

    IF v_duration IS NULL THEN
        RAISE EXCEPTION 'Film % not found', NEW.film_id;
    END IF;

    NEW.end_time := NEW.start_time + (v_duration || ' minutes')::INTERVAL;
    RETURN NEW;
END;
$$;


CREATE FUNCTION public.fn_prevent_overlapping_sessions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_duration INTEGER;
    v_new_end TIMESTAMP;
BEGIN
    SELECT duration_minutes
      INTO v_duration
      FROM films
     WHERE id = NEW.film_id;

    IF v_duration IS NULL THEN
        RAISE EXCEPTION 'Film % not found', NEW.film_id;
    END IF;

    v_new_end := NEW.start_time + (v_duration || ' minutes')::INTERVAL;

    IF EXISTS (
        SELECT 1
          FROM sessions s
         WHERE s.hall_id = NEW.hall_id
           AND s.id <> COALESCE(NEW.id, -1)
           AND NEW.start_time < s.end_time
           AND v_new_end > s.start_time
           AND s.status <> 'cancelled'
    ) THEN
        RAISE EXCEPTION 'Session overlaps with an existing session in the same hall';
    END IF;

    RETURN NEW;
END;
$$;


CREATE FUNCTION public.fn_prevent_session_deletion_with_tickets() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1
          FROM tickets t
         WHERE t.session_id = OLD.id
           AND t.status IN ('booked', 'paid')
    ) THEN
        RAISE EXCEPTION 'Cannot delete a session with active tickets';
    END IF;

    RETURN OLD;
END;
$$;
