-- Seed data
-- Cinema database project. Generated from the provided PostgreSQL dump.
-- Run from repository root with: psql -d cinema_db -f scripts/restore_split.sql

COPY public.genres (id, name) FROM stdin;
1	Комедия
2	Драма
3	Боевик
4	Ужасы
5	Мелодрама
6	Фантастика
7	Анимация
8	Приключения
9	Криминал
10	Семейный
11	Триллер
\.


COPY public.halls (id, name, rows_count, seats_per_row, hall_type, description) FROM stdin;
1	Зал 1	10	12	standard	Основной зал
2	Зал 2	8	10	vip	Премиальный зал
3	Зал 3	15	20	imax	Большой зал IMAX
\.


COPY public.films (id, title, description, genre_id, duration_minutes, age_rating, poster_url, release_date, country, is_active, created_at) FROM stdin;
1	Оппенгеймер	Историческая драма о создании атомной бомбы	2	180	18	\N	2023-07-21	США	t	2026-03-27 16:47:33.776256
2	Барби	Сатирическая комедия о Барби и Кене	1	114	12	\N	2023-07-21	США	t	2026-03-27 16:47:33.776256
3	Дюна: Часть вторая	Продолжение космической саги	6	166	16	\N	2024-02-28	США	t	2026-03-27 16:47:33.776256
4	Джон Уик 4	Экшен о легендарном киллере	3	169	18	\N	2023-03-24	США	t	2026-03-27 16:47:33.776256
5	Нечто	Культовый научно-фантастический хоррор	4	109	16	\N	1982-06-25	США	t	2026-03-27 16:47:33.776256
6	Ла-Ла Ленд	Музыкальная история о любви и мечте	5	128	12	\N	2016-12-09	США	t	2026-03-27 17:36:05.982175
7	Человек-паук: Через вселенные	Анимационный супергеройский фильм о мультивселенной	7	117	6	\N	2018-12-14	США	t	2026-03-27 17:36:05.982175
8	Паразиты	Триллер о двух семьях из разных социальных слоёв	9	132	18	\N	2019-05-30	Южная Корея	t	2026-03-27 17:36:05.982175
9	Капитан Фантастик	Семья живёт вне системы и сталкивается с реальностью	10	118	12	\N	2016-07-08	США	t	2026-03-27 17:36:05.982175
10	Гладиатор	Эпическая история о римском генерале и мести	3	155	16	\N	2000-05-05	США	t	2026-03-27 17:36:05.982175
11	Начало	Воровство секретов через проникновение в сны	6	148	12	\N	2010-07-16	США	t	2026-03-27 17:36:05.982175
12	Шерлок Холмс	Приключения знаменитого сыщика и его напарника	8	128	12	\N	2009-12-25	Великобритания	t	2026-03-27 17:36:05.982175
13	Унесённые призраками	Девочка попадает в мир духов	7	125	6	\N	2001-07-20	Япония	t	2026-03-27 17:36:05.982175
14	Зелёная книга	История дружбы и дороги через американский Юг	2	130	12	\N	2018-11-16	США	t	2026-03-27 17:36:05.982175
15	Престиж	Дуэль двух иллюзионистов, цена которой — всё	11	130	16	\N	2006-10-20	США	t	2026-03-27 17:36:05.982175
16	Клаус	Трогательная анимация о почтальоне и игрушечнике	7	97	6	\N	2019-11-15	Испания	t	2026-03-27 17:36:05.982175
17	Кролик Джоджо	Сатирическая драма о мальчике во времена войны	1	108	12	\N	2019-10-18	Новая Зеландия	t	2026-03-27 17:36:05.982175
18	Интерстеллар	Научно-фантастическая история о путешествии за пределы Солнечной системы	6	169	12	\N	2014-11-07	США	t	2026-03-27 17:36:05.982175
19	Тёмный рыцарь	Противостояние Бэтмена и Джокера	9	152	16	\N	2008-07-18	США	t	2026-03-27 17:36:05.982175
20	Остров проклятых	Психологический триллер на изолированном острове	11	138	16	\N	2010-02-19	США	t	2026-03-27 17:36:05.982175
\.


COPY public.seats (id, hall_id, row_number, seat_number, seat_type) FROM stdin;
1	1	1	1	accessible
2	1	1	2	accessible
3	1	1	3	standard
4	1	1	4	standard
5	1	1	5	standard
6	1	1	6	standard
7	1	1	7	standard
8	1	1	8	standard
9	1	1	9	standard
10	1	1	10	standard
11	1	1	11	standard
12	1	1	12	standard
13	1	2	1	standard
14	1	2	2	standard
15	1	2	3	standard
16	1	2	4	standard
17	1	2	5	standard
18	1	2	6	standard
19	1	2	7	standard
20	1	2	8	standard
21	1	2	9	standard
22	1	2	10	standard
23	1	2	11	standard
24	1	2	12	standard
25	1	3	1	standard
26	1	3	2	standard
27	1	3	3	standard
28	1	3	4	standard
29	1	3	5	standard
30	1	3	6	standard
31	1	3	7	standard
32	1	3	8	standard
33	1	3	9	standard
34	1	3	10	standard
35	1	3	11	standard
36	1	3	12	standard
37	1	4	1	standard
38	1	4	2	standard
39	1	4	3	standard
40	1	4	4	standard
41	1	4	5	standard
42	1	4	6	standard
43	1	4	7	standard
44	1	4	8	standard
45	1	4	9	standard
46	1	4	10	standard
47	1	4	11	standard
48	1	4	12	standard
49	1	5	1	standard
50	1	5	2	standard
51	1	5	3	standard
52	1	5	4	standard
53	1	5	5	standard
54	1	5	6	standard
55	1	5	7	standard
56	1	5	8	standard
57	1	5	9	standard
58	1	5	10	standard
59	1	5	11	standard
60	1	5	12	standard
61	1	6	1	standard
62	1	6	2	standard
63	1	6	3	standard
64	1	6	4	standard
65	1	6	5	standard
66	1	6	6	standard
67	1	6	7	standard
68	1	6	8	standard
69	1	6	9	standard
70	1	6	10	standard
71	1	6	11	standard
72	1	6	12	standard
73	1	7	1	standard
74	1	7	2	standard
75	1	7	3	standard
76	1	7	4	standard
77	1	7	5	standard
78	1	7	6	standard
79	1	7	7	standard
80	1	7	8	standard
81	1	7	9	standard
82	1	7	10	standard
83	1	7	11	standard
84	1	7	12	standard
85	1	8	1	standard
86	1	8	2	standard
87	1	8	3	standard
88	1	8	4	standard
89	1	8	5	standard
90	1	8	6	standard
91	1	8	7	standard
92	1	8	8	standard
93	1	8	9	standard
94	1	8	10	standard
95	1	8	11	standard
96	1	8	12	standard
97	1	9	1	standard
98	1	9	2	standard
99	1	9	3	standard
100	1	9	4	standard
101	1	9	5	standard
102	1	9	6	standard
103	1	9	7	standard
104	1	9	8	standard
105	1	9	9	standard
106	1	9	10	standard
107	1	9	11	standard
108	1	9	12	standard
109	1	10	1	standard
110	1	10	2	standard
111	1	10	3	standard
112	1	10	4	standard
113	1	10	5	standard
114	1	10	6	standard
115	1	10	7	standard
116	1	10	8	standard
117	1	10	9	standard
118	1	10	10	standard
119	1	10	11	standard
120	1	10	12	standard
121	2	1	1	accessible
122	2	1	2	accessible
123	2	1	3	vip
124	2	1	4	vip
125	2	1	5	vip
126	2	1	6	vip
127	2	1	7	vip
128	2	1	8	vip
129	2	1	9	vip
130	2	1	10	vip
131	2	2	1	vip
132	2	2	2	vip
133	2	2	3	vip
134	2	2	4	vip
135	2	2	5	vip
136	2	2	6	vip
137	2	2	7	vip
138	2	2	8	vip
139	2	2	9	vip
140	2	2	10	vip
141	2	3	1	standard
142	2	3	2	standard
143	2	3	3	standard
144	2	3	4	standard
145	2	3	5	standard
146	2	3	6	standard
147	2	3	7	standard
148	2	3	8	standard
149	2	3	9	standard
150	2	3	10	standard
151	2	4	1	standard
152	2	4	2	standard
153	2	4	3	standard
154	2	4	4	standard
155	2	4	5	standard
156	2	4	6	standard
157	2	4	7	standard
158	2	4	8	standard
159	2	4	9	standard
160	2	4	10	standard
161	2	5	1	standard
162	2	5	2	standard
163	2	5	3	standard
164	2	5	4	standard
165	2	5	5	standard
166	2	5	6	standard
167	2	5	7	standard
168	2	5	8	standard
169	2	5	9	standard
170	2	5	10	standard
171	2	6	1	standard
172	2	6	2	standard
173	2	6	3	standard
174	2	6	4	standard
175	2	6	5	standard
176	2	6	6	standard
177	2	6	7	standard
178	2	6	8	standard
179	2	6	9	standard
180	2	6	10	standard
181	2	7	1	standard
182	2	7	2	standard
183	2	7	3	standard
184	2	7	4	standard
185	2	7	5	standard
186	2	7	6	standard
187	2	7	7	standard
188	2	7	8	standard
189	2	7	9	standard
190	2	7	10	standard
191	2	8	1	standard
192	2	8	2	standard
193	2	8	3	standard
194	2	8	4	standard
195	2	8	5	standard
196	2	8	6	standard
197	2	8	7	standard
198	2	8	8	standard
199	2	8	9	standard
200	2	8	10	standard
201	3	1	1	accessible
202	3	1	2	accessible
203	3	1	3	standard
204	3	1	4	standard
205	3	1	5	standard
206	3	1	6	standard
207	3	1	7	standard
208	3	1	8	standard
209	3	1	9	standard
210	3	1	10	standard
211	3	1	11	standard
212	3	1	12	standard
213	3	1	13	standard
214	3	1	14	standard
215	3	1	15	standard
216	3	1	16	standard
217	3	1	17	standard
218	3	1	18	standard
219	3	1	19	standard
220	3	1	20	standard
221	3	2	1	standard
222	3	2	2	standard
223	3	2	3	standard
224	3	2	4	standard
225	3	2	5	standard
226	3	2	6	standard
227	3	2	7	standard
228	3	2	8	standard
229	3	2	9	standard
230	3	2	10	standard
231	3	2	11	standard
232	3	2	12	standard
233	3	2	13	standard
234	3	2	14	standard
235	3	2	15	standard
236	3	2	16	standard
237	3	2	17	standard
238	3	2	18	standard
239	3	2	19	standard
240	3	2	20	standard
241	3	3	1	standard
242	3	3	2	standard
243	3	3	3	standard
244	3	3	4	standard
245	3	3	5	standard
246	3	3	6	standard
247	3	3	7	standard
248	3	3	8	standard
249	3	3	9	standard
250	3	3	10	standard
251	3	3	11	standard
252	3	3	12	standard
253	3	3	13	standard
254	3	3	14	standard
255	3	3	15	standard
256	3	3	16	standard
257	3	3	17	standard
258	3	3	18	standard
259	3	3	19	standard
260	3	3	20	standard
261	3	4	1	standard
262	3	4	2	standard
263	3	4	3	standard
264	3	4	4	standard
265	3	4	5	standard
266	3	4	6	standard
267	3	4	7	standard
268	3	4	8	standard
269	3	4	9	standard
270	3	4	10	standard
271	3	4	11	standard
272	3	4	12	standard
273	3	4	13	standard
274	3	4	14	standard
275	3	4	15	standard
276	3	4	16	standard
277	3	4	17	standard
278	3	4	18	standard
279	3	4	19	standard
280	3	4	20	standard
281	3	5	1	standard
282	3	5	2	standard
283	3	5	3	standard
284	3	5	4	standard
285	3	5	5	standard
286	3	5	6	standard
287	3	5	7	standard
288	3	5	8	standard
289	3	5	9	standard
290	3	5	10	standard
291	3	5	11	standard
292	3	5	12	standard
293	3	5	13	standard
294	3	5	14	standard
295	3	5	15	standard
296	3	5	16	standard
297	3	5	17	standard
298	3	5	18	standard
299	3	5	19	standard
300	3	5	20	standard
301	3	6	1	standard
302	3	6	2	standard
303	3	6	3	standard
304	3	6	4	standard
305	3	6	5	standard
306	3	6	6	standard
307	3	6	7	standard
308	3	6	8	standard
309	3	6	9	standard
310	3	6	10	standard
311	3	6	11	standard
312	3	6	12	standard
313	3	6	13	standard
314	3	6	14	standard
315	3	6	15	standard
316	3	6	16	standard
317	3	6	17	standard
318	3	6	18	standard
319	3	6	19	standard
320	3	6	20	standard
321	3	7	1	standard
322	3	7	2	standard
323	3	7	3	standard
324	3	7	4	standard
325	3	7	5	standard
326	3	7	6	standard
327	3	7	7	standard
328	3	7	8	standard
329	3	7	9	standard
330	3	7	10	standard
331	3	7	11	standard
332	3	7	12	standard
333	3	7	13	standard
334	3	7	14	standard
335	3	7	15	standard
336	3	7	16	standard
337	3	7	17	standard
338	3	7	18	standard
339	3	7	19	standard
340	3	7	20	standard
341	3	8	1	standard
342	3	8	2	standard
343	3	8	3	standard
344	3	8	4	standard
345	3	8	5	standard
346	3	8	6	standard
347	3	8	7	standard
348	3	8	8	standard
349	3	8	9	standard
350	3	8	10	standard
351	3	8	11	standard
352	3	8	12	standard
353	3	8	13	standard
354	3	8	14	standard
355	3	8	15	standard
356	3	8	16	standard
357	3	8	17	standard
358	3	8	18	standard
359	3	8	19	standard
360	3	8	20	standard
361	3	9	1	standard
362	3	9	2	standard
363	3	9	3	standard
364	3	9	4	standard
365	3	9	5	standard
366	3	9	6	standard
367	3	9	7	standard
368	3	9	8	standard
369	3	9	9	standard
370	3	9	10	standard
371	3	9	11	standard
372	3	9	12	standard
373	3	9	13	standard
374	3	9	14	standard
375	3	9	15	standard
376	3	9	16	standard
377	3	9	17	standard
378	3	9	18	standard
379	3	9	19	standard
380	3	9	20	standard
381	3	10	1	standard
382	3	10	2	standard
383	3	10	3	standard
384	3	10	4	standard
385	3	10	5	standard
386	3	10	6	standard
387	3	10	7	standard
388	3	10	8	standard
389	3	10	9	standard
390	3	10	10	standard
391	3	10	11	standard
392	3	10	12	standard
393	3	10	13	standard
394	3	10	14	standard
395	3	10	15	standard
396	3	10	16	standard
397	3	10	17	standard
398	3	10	18	standard
399	3	10	19	standard
400	3	10	20	standard
401	3	11	1	standard
402	3	11	2	standard
403	3	11	3	standard
404	3	11	4	standard
405	3	11	5	standard
406	3	11	6	standard
407	3	11	7	standard
408	3	11	8	standard
409	3	11	9	standard
410	3	11	10	standard
411	3	11	11	standard
412	3	11	12	standard
413	3	11	13	standard
414	3	11	14	standard
415	3	11	15	standard
416	3	11	16	standard
417	3	11	17	standard
418	3	11	18	standard
419	3	11	19	standard
420	3	11	20	standard
421	3	12	1	standard
422	3	12	2	standard
423	3	12	3	standard
424	3	12	4	standard
425	3	12	5	standard
426	3	12	6	standard
427	3	12	7	standard
428	3	12	8	standard
429	3	12	9	standard
430	3	12	10	standard
431	3	12	11	standard
432	3	12	12	standard
433	3	12	13	standard
434	3	12	14	standard
435	3	12	15	standard
436	3	12	16	standard
437	3	12	17	standard
438	3	12	18	standard
439	3	12	19	standard
440	3	12	20	standard
441	3	13	1	standard
442	3	13	2	standard
443	3	13	3	standard
444	3	13	4	standard
445	3	13	5	standard
446	3	13	6	standard
447	3	13	7	standard
448	3	13	8	standard
449	3	13	9	standard
450	3	13	10	standard
451	3	13	11	standard
452	3	13	12	standard
453	3	13	13	standard
454	3	13	14	standard
455	3	13	15	standard
456	3	13	16	standard
457	3	13	17	standard
458	3	13	18	standard
459	3	13	19	standard
460	3	13	20	standard
461	3	14	1	standard
462	3	14	2	standard
463	3	14	3	standard
464	3	14	4	standard
465	3	14	5	standard
466	3	14	6	standard
467	3	14	7	standard
468	3	14	8	standard
469	3	14	9	standard
470	3	14	10	standard
471	3	14	11	standard
472	3	14	12	standard
473	3	14	13	standard
474	3	14	14	standard
475	3	14	15	standard
476	3	14	16	standard
477	3	14	17	standard
478	3	14	18	standard
479	3	14	19	standard
480	3	14	20	standard
481	3	15	1	standard
482	3	15	2	standard
483	3	15	3	standard
484	3	15	4	standard
485	3	15	5	standard
486	3	15	6	standard
487	3	15	7	standard
488	3	15	8	standard
489	3	15	9	standard
490	3	15	10	standard
491	3	15	11	standard
492	3	15	12	standard
493	3	15	13	standard
494	3	15	14	standard
495	3	15	15	standard
496	3	15	16	standard
497	3	15	17	standard
498	3	15	18	standard
499	3	15	19	standard
500	3	15	20	standard
\.


SELECT pg_catalog.setval('public.genres_id_seq', 11, true);


SELECT pg_catalog.setval('public.halls_id_seq', 3, true);


SELECT pg_catalog.setval('public.films_id_seq', 20, true);


SELECT pg_catalog.setval('public.seats_id_seq', 500, true);
