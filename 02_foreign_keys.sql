-- Foreign keys
-- Cinema database project. Generated from the provided PostgreSQL dump.
-- Run from repository root with: psql -d cinema_db -f scripts/restore_split.sql

ALTER TABLE ONLY public.films
    ADD CONSTRAINT films_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES public.genres(id) ON DELETE SET NULL;


ALTER TABLE ONLY public.seats
    ADD CONSTRAINT seats_hall_id_fkey FOREIGN KEY (hall_id) REFERENCES public.halls(id) ON DELETE CASCADE;


ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_film_id_fkey FOREIGN KEY (film_id) REFERENCES public.films(id) ON DELETE CASCADE;


ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_hall_id_fkey FOREIGN KEY (hall_id) REFERENCES public.halls(id) ON DELETE CASCADE;


ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.sessions(id) ON DELETE CASCADE;


ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_seat_id_fkey FOREIGN KEY (seat_id) REFERENCES public.seats(id) ON DELETE CASCADE;


ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


ALTER TABLE ONLY public.ticket_status_log
    ADD CONSTRAINT ticket_status_log_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON DELETE CASCADE;
