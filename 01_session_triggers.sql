-- Session triggers
-- Cinema database project. Generated from the provided PostgreSQL dump.
-- Run from repository root with: psql -d cinema_db -f scripts/restore_split.sql

CREATE TRIGGER trg_sessions_prevent_overlap BEFORE INSERT OR UPDATE OF film_id, hall_id, start_time ON public.sessions FOR EACH ROW EXECUTE FUNCTION public.fn_prevent_overlapping_sessions();


CREATE TRIGGER trg_sessions_protect_delete BEFORE DELETE ON public.sessions FOR EACH ROW EXECUTE FUNCTION public.fn_prevent_session_deletion_with_tickets();


CREATE TRIGGER trg_sessions_set_end_time BEFORE INSERT OR UPDATE OF film_id, start_time ON public.sessions FOR EACH ROW EXECUTE FUNCTION public.fn_set_session_end_time();
