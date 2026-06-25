-- Ticket triggers
-- Cinema database project. Generated from the provided PostgreSQL dump.
-- Run from repository root with: psql -d cinema_db -f scripts/restore_split.sql

CREATE TRIGGER trg_tickets_block_late_cancel BEFORE UPDATE OF status ON public.tickets FOR EACH ROW WHEN (((new.status)::text = ANY ((ARRAY['cancelled'::character varying, 'refunded'::character varying])::text[]))) EXECUTE FUNCTION public.fn_block_late_ticket_cancellation();


CREATE TRIGGER trg_tickets_calculate_price BEFORE INSERT ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.fn_calculate_ticket_price();


CREATE TRIGGER trg_tickets_check_seat BEFORE INSERT ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.fn_check_seat_availability();


CREATE TRIGGER trg_tickets_log_status AFTER UPDATE OF status ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.fn_log_ticket_status_change();
