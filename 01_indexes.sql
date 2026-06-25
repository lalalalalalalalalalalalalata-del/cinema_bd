-- Indexes
-- Cinema database project. Generated from the provided PostgreSQL dump.
-- Run from repository root with: psql -d cinema_db -f scripts/restore_split.sql

CREATE INDEX idx_films_genre_id ON public.films USING btree (genre_id);


CREATE INDEX idx_halls_type ON public.halls USING btree (hall_type);


CREATE INDEX idx_seats_hall_id ON public.seats USING btree (hall_id);


CREATE INDEX idx_sessions_film_id ON public.sessions USING btree (film_id);


CREATE INDEX idx_sessions_hall_id ON public.sessions USING btree (hall_id);


CREATE INDEX idx_sessions_start_time ON public.sessions USING btree (start_time);


CREATE INDEX idx_tickets_session_id ON public.tickets USING btree (session_id);


CREATE INDEX idx_tickets_status ON public.tickets USING btree (status);


CREATE INDEX idx_tickets_user_id ON public.tickets USING btree (user_id);


CREATE UNIQUE INDEX uq_tickets_active_seat ON public.tickets USING btree (session_id, seat_id) WHERE ((status)::text = ANY ((ARRAY['booked'::character varying, 'paid'::character varying])::text[]));
