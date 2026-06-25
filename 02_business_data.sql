-- Seed data
-- Cinema database project. Generated from the provided PostgreSQL dump.
-- Run from repository root with: psql -d cinema_db -f scripts/restore_split.sql

COPY public.users (id, full_name, email, phone, birth_date, password_hash, registered_at, is_active) FROM stdin;
1	Сподобаева Леля Витальевна	lelya@example.com	+79600000001	2000-05-10	hash1	2026-03-27 16:47:33.776256	t
2	Пряхин Артем Геннадьевич	artem@example.com	+79600000002	1999-09-17	hash2	2026-03-27 16:47:33.776256	t
3	Иванова Мария Сергеевна	maria@example.com	+79600000003	1958-03-05	hash3	2026-03-27 16:47:33.776256	t
4	Петрова Анна Ильинична	anna@example.com	+79600000004	2006-11-12	hash4	2026-03-27 16:47:33.776256	t
5	Козлов Дмитрий Олегович	dmitry@example.com	+79600000005	\N	hash5	2026-03-27 16:47:33.776256	t
\.


COPY public.sessions (id, film_id, hall_id, start_time, end_time, base_price, status, created_at) FROM stdin;
1	1	1	2026-06-20 10:00:00	2026-06-20 13:00:00	300.00	scheduled	2026-03-27 16:47:33.776256
2	2	1	2026-06-20 14:00:00	2026-06-20 15:54:00	350.00	scheduled	2026-03-27 16:47:33.776256
3	3	2	2026-06-20 11:30:00	2026-06-20 14:16:00	500.00	scheduled	2026-03-27 16:47:33.776256
4	4	2	2026-06-20 18:30:00	2026-06-20 21:19:00	550.00	scheduled	2026-03-27 16:47:33.776256
5	5	3	2026-06-20 21:00:00	2026-06-20 22:49:00	600.00	scheduled	2026-03-27 16:47:33.776256
6	3	1	2026-06-21 09:30:00	2026-06-21 12:16:00	280.00	scheduled	2026-03-27 16:47:33.776256
7	1	2	2026-06-21 16:00:00	2026-06-21 19:00:00	450.00	scheduled	2026-03-27 16:47:33.776256
8	16	1	2026-06-23 10:30:00	2026-06-23 12:07:00	300.00	scheduled	2026-03-27 17:36:05.982175
9	12	1	2026-06-24 14:00:00	2026-06-24 16:08:00	430.00	scheduled	2026-03-27 17:36:05.982175
10	11	1	2026-06-22 13:30:00	2026-06-22 15:58:00	400.00	scheduled	2026-03-27 17:36:05.982175
11	10	1	2026-06-22 18:00:00	2026-06-22 20:35:00	380.00	scheduled	2026-03-27 17:36:05.982175
12	20	2	2026-06-23 18:30:00	2026-06-23 20:48:00	500.00	scheduled	2026-03-27 17:36:05.982175
13	15	2	2026-06-24 11:30:00	2026-06-24 13:40:00	470.00	scheduled	2026-03-27 17:36:05.982175
14	14	2	2026-06-22 15:30:00	2026-06-22 17:40:00	420.00	scheduled	2026-03-27 17:36:05.982175
15	8	2	2026-06-22 11:00:00	2026-06-22 13:12:00	450.00	scheduled	2026-03-27 17:36:05.982175
16	18	3	2026-06-22 10:00:00	2026-06-22 12:49:00	700.00	scheduled	2026-03-27 17:36:05.982175
17	13	3	2026-06-24 19:00:00	2026-06-24 21:05:00	600.00	scheduled	2026-03-27 17:36:05.982175
18	7	3	2026-06-22 16:30:00	2026-06-22 18:27:00	650.00	scheduled	2026-03-27 17:36:05.982175
19	6	3	2026-06-23 12:30:00	2026-06-23 14:38:00	550.00	scheduled	2026-03-27 17:36:05.982175
\.


COPY public.tickets (id, session_id, seat_id, user_id, price, status, sale_time, payment_method, comment) FROM stdin;
3	2	13	3	245.00	paid	2026-06-19 13:00:00	cash	\N
4	3	121	4	342.00	paid	2026-06-19 14:00:00	card	\N
6	5	401	1	600.00	paid	2026-06-19 16:00:00	card	\N
7	6	3	2	224.00	paid	2026-06-20 08:00:00	card	\N
2	1	2	2	228.00	paid	2026-06-19 12:05:00	\N	\N
5	4	122	5	522.50	cancelled	2026-06-19 15:00:00	\N	\N
1	1	1	1	228.00	cancelled	2026-06-19 12:00:00	card	First purchase
9	16	201	1	532.00	paid	2026-06-21 12:00:00	card	Interstellar ticket 1
10	16	202	2	532.00	booked	2026-06-21 12:05:00	\N	Interstellar ticket 2
11	10	5	3	280.00	paid	2026-06-21 13:00:00	cash	Inception ticket
12	11	6	4	342.00	paid	2026-06-21 14:00:00	card	Gladiator ticket
13	15	125	5	450.00	paid	2026-06-21 15:00:00	card	Parasite ticket
14	14	126	1	525.00	booked	2026-06-21 15:10:00	\N	Green Book ticket
15	18	250	2	650.00	paid	2026-06-21 16:00:00	card	Spider-Verse ticket
16	8	11	3	168.00	paid	2026-06-21 17:00:00	cash	Klaus ticket
17	12	135	4	562.50	paid	2026-06-21 18:00:00	card	Shutter Island ticket
18	19	260	5	550.00	booked	2026-06-21 19:00:00	\N	La La Land ticket
19	9	12	1	430.00	paid	2026-06-21 20:00:00	card	Sherlock ticket
20	13	136	2	470.00	paid	2026-06-21 21:00:00	card	Prestige ticket
21	17	300	3	420.00	paid	2026-06-21 22:00:00	cash	Spirited Away ticket
\.


COPY public.ticket_status_log (id, ticket_id, old_status, new_status, changed_at, changed_by) FROM stdin;
1	2	booked	paid	2026-03-27 16:47:33.776256	postgres
2	5	booked	cancelled	2026-03-27 16:47:33.776256	postgres
3	1	paid	cancelled	2026-03-27 17:28:39.094834	postgres
\.


SELECT pg_catalog.setval('public.users_id_seq', 5, true);


SELECT pg_catalog.setval('public.sessions_id_seq', 19, true);


SELECT pg_catalog.setval('public.tickets_id_seq', 21, true);


SELECT pg_catalog.setval('public.ticket_status_log_id_seq', 3, true);
