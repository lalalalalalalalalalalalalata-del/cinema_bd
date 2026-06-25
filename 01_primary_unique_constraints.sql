-- Primary and unique constraints
-- Cinema database project. Generated from the provided PostgreSQL dump.
-- Run from repository root with: psql -d cinema_db -f scripts/restore_split.sql

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (id);


ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_name_key UNIQUE (name);


ALTER TABLE ONLY public.films
    ADD CONSTRAINT films_pkey PRIMARY KEY (id);


ALTER TABLE ONLY public.halls
    ADD CONSTRAINT halls_pkey PRIMARY KEY (id);


ALTER TABLE ONLY public.halls
    ADD CONSTRAINT halls_name_key UNIQUE (name);


ALTER TABLE ONLY public.seats
    ADD CONSTRAINT seats_pkey PRIMARY KEY (id);


ALTER TABLE ONLY public.seats
    ADD CONSTRAINT seats_hall_id_row_number_seat_number_key UNIQUE (hall_id, row_number, seat_number);


ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_hall_id_start_time_key UNIQUE (hall_id, start_time);


ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


ALTER TABLE ONLY public.ticket_status_log
    ADD CONSTRAINT ticket_status_log_pkey PRIMARY KEY (id);
