--
-- PostgreSQL database dump
--

\restrict ymPTAqav3dNVc4xDct9aZ91IiCA3vKNGY0LZmGz7gkML1e7dQkckXYS7TDs9ymn

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-04-04 01:59:06 MSK

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 252 (class 1255 OID 16587)
-- Name: fn_block_late_ticket_cancellation(); Type: FUNCTION; Schema: public; Owner: postgres
--

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


ALTER FUNCTION public.fn_block_late_ticket_cancellation() OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 16584)
-- Name: fn_calculate_ticket_price(); Type: FUNCTION; Schema: public; Owner: postgres
--

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


ALTER FUNCTION public.fn_calculate_ticket_price() OWNER TO postgres;

--
-- TOC entry 237 (class 1255 OID 16583)
-- Name: fn_check_seat_availability(); Type: FUNCTION; Schema: public; Owner: postgres
--

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


ALTER FUNCTION public.fn_check_seat_availability() OWNER TO postgres;

--
-- TOC entry 253 (class 1255 OID 16595)
-- Name: fn_generate_seats_for_hall(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

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


ALTER FUNCTION public.fn_generate_seats_for_hall(p_hall_id integer) OWNER TO postgres;

--
-- TOC entry 250 (class 1255 OID 16585)
-- Name: fn_log_ticket_status_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

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


ALTER FUNCTION public.fn_log_ticket_status_change() OWNER TO postgres;

--
-- TOC entry 236 (class 1255 OID 16582)
-- Name: fn_prevent_overlapping_sessions(); Type: FUNCTION; Schema: public; Owner: postgres
--

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


ALTER FUNCTION public.fn_prevent_overlapping_sessions() OWNER TO postgres;

--
-- TOC entry 251 (class 1255 OID 16586)
-- Name: fn_prevent_session_deletion_with_tickets(); Type: FUNCTION; Schema: public; Owner: postgres
--

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


ALTER FUNCTION public.fn_prevent_session_deletion_with_tickets() OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 16581)
-- Name: fn_set_session_end_time(); Type: FUNCTION; Schema: public; Owner: postgres
--

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


ALTER FUNCTION public.fn_set_session_end_time() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 222 (class 1259 OID 16401)
-- Name: films; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.films (
    id integer NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    genre_id integer,
    duration_minutes integer NOT NULL,
    age_rating integer NOT NULL,
    poster_url character varying(500),
    release_date date,
    country character varying(100),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT films_age_rating_check CHECK (((age_rating >= 0) AND (age_rating <= 21))),
    CONSTRAINT films_duration_minutes_check CHECK ((duration_minutes > 0))
);


ALTER TABLE public.films OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16400)
-- Name: films_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.films_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.films_id_seq OWNER TO postgres;

--
-- TOC entry 3965 (class 0 OID 0)
-- Dependencies: 221
-- Name: films_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.films_id_seq OWNED BY public.films.id;


--
-- TOC entry 220 (class 1259 OID 16390)
-- Name: genres; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.genres (
    id integer NOT NULL,
    name character varying(80) NOT NULL
);


ALTER TABLE public.genres OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16389)
-- Name: genres_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.genres_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.genres_id_seq OWNER TO postgres;

--
-- TOC entry 3966 (class 0 OID 0)
-- Dependencies: 219
-- Name: genres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.genres_id_seq OWNED BY public.genres.id;


--
-- TOC entry 224 (class 1259 OID 16425)
-- Name: halls; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.halls (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    rows_count integer NOT NULL,
    seats_per_row integer NOT NULL,
    hall_type character varying(20) DEFAULT 'standard'::character varying NOT NULL,
    description text,
    CONSTRAINT halls_hall_type_check CHECK (((hall_type)::text = ANY ((ARRAY['standard'::character varying, 'vip'::character varying, 'imax'::character varying])::text[]))),
    CONSTRAINT halls_rows_count_check CHECK ((rows_count > 0)),
    CONSTRAINT halls_seats_per_row_check CHECK ((seats_per_row > 0))
);


ALTER TABLE public.halls OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16424)
-- Name: halls_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.halls_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.halls_id_seq OWNER TO postgres;

--
-- TOC entry 3967 (class 0 OID 0)
-- Dependencies: 223
-- Name: halls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.halls_id_seq OWNED BY public.halls.id;


--
-- TOC entry 226 (class 1259 OID 16445)
-- Name: seats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.seats (
    id integer NOT NULL,
    hall_id integer NOT NULL,
    row_number integer NOT NULL,
    seat_number integer NOT NULL,
    seat_type character varying(20) DEFAULT 'standard'::character varying NOT NULL,
    CONSTRAINT seats_row_number_check CHECK ((row_number > 0)),
    CONSTRAINT seats_seat_number_check CHECK ((seat_number > 0)),
    CONSTRAINT seats_seat_type_check CHECK (((seat_type)::text = ANY ((ARRAY['standard'::character varying, 'vip'::character varying, 'accessible'::character varying])::text[])))
);


ALTER TABLE public.seats OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16444)
-- Name: seats_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.seats_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seats_id_seq OWNER TO postgres;

--
-- TOC entry 3968 (class 0 OID 0)
-- Dependencies: 225
-- Name: seats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.seats_id_seq OWNED BY public.seats.id;


--
-- TOC entry 230 (class 1259 OID 16487)
-- Name: sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sessions (
    id integer NOT NULL,
    film_id integer NOT NULL,
    hall_id integer NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    base_price numeric(10,2) NOT NULL,
    status character varying(20) DEFAULT 'scheduled'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT sessions_base_price_check CHECK ((base_price >= (0)::numeric)),
    CONSTRAINT sessions_check CHECK ((start_time < end_time)),
    CONSTRAINT sessions_status_check CHECK (((status)::text = ANY ((ARRAY['scheduled'::character varying, 'sold_out'::character varying, 'cancelled'::character varying, 'finished'::character varying])::text[])))
);


ALTER TABLE public.sessions OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16486)
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sessions_id_seq OWNER TO postgres;

--
-- TOC entry 3969 (class 0 OID 0)
-- Dependencies: 229
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- TOC entry 234 (class 1259 OID 16553)
-- Name: ticket_status_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ticket_status_log (
    id integer NOT NULL,
    ticket_id integer NOT NULL,
    old_status character varying(20),
    new_status character varying(20) NOT NULL,
    changed_at timestamp without time zone DEFAULT now() NOT NULL,
    changed_by character varying(100) DEFAULT CURRENT_USER NOT NULL
);


ALTER TABLE public.ticket_status_log OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16552)
-- Name: ticket_status_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ticket_status_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ticket_status_log_id_seq OWNER TO postgres;

--
-- TOC entry 3970 (class 0 OID 0)
-- Dependencies: 233
-- Name: ticket_status_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ticket_status_log_id_seq OWNED BY public.ticket_status_log.id;


--
-- TOC entry 232 (class 1259 OID 16519)
-- Name: tickets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tickets (
    id integer NOT NULL,
    session_id integer NOT NULL,
    seat_id integer NOT NULL,
    user_id integer,
    price numeric(10,2) NOT NULL,
    status character varying(20) DEFAULT 'booked'::character varying NOT NULL,
    sale_time timestamp without time zone DEFAULT now() NOT NULL,
    payment_method character varying(30),
    comment text,
    CONSTRAINT tickets_price_check CHECK ((price >= (0)::numeric)),
    CONSTRAINT tickets_status_check CHECK (((status)::text = ANY ((ARRAY['booked'::character varying, 'paid'::character varying, 'cancelled'::character varying, 'refunded'::character varying])::text[])))
);


ALTER TABLE public.tickets OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16518)
-- Name: tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tickets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tickets_id_seq OWNER TO postgres;

--
-- TOC entry 3971 (class 0 OID 0)
-- Dependencies: 231
-- Name: tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tickets_id_seq OWNED BY public.tickets.id;


--
-- TOC entry 228 (class 1259 OID 16468)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    full_name character varying(200) NOT NULL,
    email character varying(200) NOT NULL,
    phone character varying(30),
    birth_date date,
    password_hash character varying(255) NOT NULL,
    registered_at timestamp without time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16467)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 3972 (class 0 OID 0)
-- Dependencies: 227
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 3714 (class 2604 OID 16404)
-- Name: films id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.films ALTER COLUMN id SET DEFAULT nextval('public.films_id_seq'::regclass);


--
-- TOC entry 3713 (class 2604 OID 16393)
-- Name: genres id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres ALTER COLUMN id SET DEFAULT nextval('public.genres_id_seq'::regclass);


--
-- TOC entry 3717 (class 2604 OID 16428)
-- Name: halls id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.halls ALTER COLUMN id SET DEFAULT nextval('public.halls_id_seq'::regclass);


--
-- TOC entry 3719 (class 2604 OID 16448)
-- Name: seats id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seats ALTER COLUMN id SET DEFAULT nextval('public.seats_id_seq'::regclass);


--
-- TOC entry 3724 (class 2604 OID 16490)
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- TOC entry 3730 (class 2604 OID 16556)
-- Name: ticket_status_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_status_log ALTER COLUMN id SET DEFAULT nextval('public.ticket_status_log_id_seq'::regclass);


--
-- TOC entry 3727 (class 2604 OID 16522)
-- Name: tickets id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets ALTER COLUMN id SET DEFAULT nextval('public.tickets_id_seq'::regclass);


--
-- TOC entry 3721 (class 2604 OID 16471)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 3947 (class 0 OID 16401)
-- Dependencies: 222
-- Data for Name: films; Type: TABLE DATA; Schema: public; Owner: postgres
--

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


--
-- TOC entry 3945 (class 0 OID 16390)
-- Dependencies: 220
-- Data for Name: genres; Type: TABLE DATA; Schema: public; Owner: postgres
--

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


--
-- TOC entry 3949 (class 0 OID 16425)
-- Dependencies: 224
-- Data for Name: halls; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.halls (id, name, rows_count, seats_per_row, hall_type, description) FROM stdin;
1	Зал 1	10	12	standard	Основной зал
2	Зал 2	8	10	vip	Премиальный зал
3	Зал 3	15	20	imax	Большой зал IMAX
\.


--
-- TOC entry 3951 (class 0 OID 16445)
-- Dependencies: 226
-- Data for Name: seats; Type: TABLE DATA; Schema: public; Owner: postgres
--

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


--
-- TOC entry 3955 (class 0 OID 16487)
-- Dependencies: 230
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

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


--
-- TOC entry 3959 (class 0 OID 16553)
-- Dependencies: 234
-- Data for Name: ticket_status_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ticket_status_log (id, ticket_id, old_status, new_status, changed_at, changed_by) FROM stdin;
1	2	booked	paid	2026-03-27 16:47:33.776256	postgres
2	5	booked	cancelled	2026-03-27 16:47:33.776256	postgres
3	1	paid	cancelled	2026-03-27 17:28:39.094834	postgres
\.


--
-- TOC entry 3957 (class 0 OID 16519)
-- Dependencies: 232
-- Data for Name: tickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

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


--
-- TOC entry 3953 (class 0 OID 16468)
-- Dependencies: 228
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, full_name, email, phone, birth_date, password_hash, registered_at, is_active) FROM stdin;
1	Сподобаева Леля Витальевна	lelya@example.com	+79600000001	2000-05-10	hash1	2026-03-27 16:47:33.776256	t
2	Пряхин Артем Геннадьевич	artem@example.com	+79600000002	1999-09-17	hash2	2026-03-27 16:47:33.776256	t
3	Иванова Мария Сергеевна	maria@example.com	+79600000003	1958-03-05	hash3	2026-03-27 16:47:33.776256	t
4	Петрова Анна Ильинична	anna@example.com	+79600000004	2006-11-12	hash4	2026-03-27 16:47:33.776256	t
5	Козлов Дмитрий Олегович	dmitry@example.com	+79600000005	\N	hash5	2026-03-27 16:47:33.776256	t
\.


--
-- TOC entry 3973 (class 0 OID 0)
-- Dependencies: 221
-- Name: films_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.films_id_seq', 20, true);


--
-- TOC entry 3974 (class 0 OID 0)
-- Dependencies: 219
-- Name: genres_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.genres_id_seq', 11, true);


--
-- TOC entry 3975 (class 0 OID 0)
-- Dependencies: 223
-- Name: halls_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.halls_id_seq', 3, true);


--
-- TOC entry 3976 (class 0 OID 0)
-- Dependencies: 225
-- Name: seats_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.seats_id_seq', 500, true);


--
-- TOC entry 3977 (class 0 OID 0)
-- Dependencies: 229
-- Name: sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sessions_id_seq', 19, true);


--
-- TOC entry 3978 (class 0 OID 0)
-- Dependencies: 233
-- Name: ticket_status_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ticket_status_log_id_seq', 3, true);


--
-- TOC entry 3979 (class 0 OID 0)
-- Dependencies: 231
-- Name: tickets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tickets_id_seq', 21, true);


--
-- TOC entry 3980 (class 0 OID 0)
-- Dependencies: 227
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 5, true);


--
-- TOC entry 3751 (class 2606 OID 16418)
-- Name: films films_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.films
    ADD CONSTRAINT films_pkey PRIMARY KEY (id);


--
-- TOC entry 3747 (class 2606 OID 16399)
-- Name: genres genres_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_name_key UNIQUE (name);


--
-- TOC entry 3749 (class 2606 OID 16397)
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (id);


--
-- TOC entry 3754 (class 2606 OID 16443)
-- Name: halls halls_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.halls
    ADD CONSTRAINT halls_name_key UNIQUE (name);


--
-- TOC entry 3756 (class 2606 OID 16441)
-- Name: halls halls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.halls
    ADD CONSTRAINT halls_pkey PRIMARY KEY (id);


--
-- TOC entry 3760 (class 2606 OID 16461)
-- Name: seats seats_hall_id_row_number_seat_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seats
    ADD CONSTRAINT seats_hall_id_row_number_seat_number_key UNIQUE (hall_id, row_number, seat_number);


--
-- TOC entry 3762 (class 2606 OID 16459)
-- Name: seats seats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seats
    ADD CONSTRAINT seats_pkey PRIMARY KEY (id);


--
-- TOC entry 3771 (class 2606 OID 16507)
-- Name: sessions sessions_hall_id_start_time_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_hall_id_start_time_key UNIQUE (hall_id, start_time);


--
-- TOC entry 3773 (class 2606 OID 16505)
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 3781 (class 2606 OID 16565)
-- Name: ticket_status_log ticket_status_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_status_log
    ADD CONSTRAINT ticket_status_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3778 (class 2606 OID 16536)
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- TOC entry 3764 (class 2606 OID 16485)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3766 (class 2606 OID 16483)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3752 (class 1259 OID 16572)
-- Name: idx_films_genre_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_films_genre_id ON public.films USING btree (genre_id);


--
-- TOC entry 3757 (class 1259 OID 16573)
-- Name: idx_halls_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_halls_type ON public.halls USING btree (hall_type);


--
-- TOC entry 3758 (class 1259 OID 16574)
-- Name: idx_seats_hall_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_seats_hall_id ON public.seats USING btree (hall_id);


--
-- TOC entry 3767 (class 1259 OID 16576)
-- Name: idx_sessions_film_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_film_id ON public.sessions USING btree (film_id);


--
-- TOC entry 3768 (class 1259 OID 16577)
-- Name: idx_sessions_hall_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_hall_id ON public.sessions USING btree (hall_id);


--
-- TOC entry 3769 (class 1259 OID 16575)
-- Name: idx_sessions_start_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_start_time ON public.sessions USING btree (start_time);


--
-- TOC entry 3774 (class 1259 OID 16578)
-- Name: idx_tickets_session_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_session_id ON public.tickets USING btree (session_id);


--
-- TOC entry 3775 (class 1259 OID 16580)
-- Name: idx_tickets_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_status ON public.tickets USING btree (status);


--
-- TOC entry 3776 (class 1259 OID 16579)
-- Name: idx_tickets_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_user_id ON public.tickets USING btree (user_id);


--
-- TOC entry 3779 (class 1259 OID 16571)
-- Name: uq_tickets_active_seat; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_tickets_active_seat ON public.tickets USING btree (session_id, seat_id) WHERE ((status)::text = ANY ((ARRAY['booked'::character varying, 'paid'::character varying])::text[]));


--
-- TOC entry 3790 (class 2620 OID 16589)
-- Name: sessions trg_sessions_prevent_overlap; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_sessions_prevent_overlap BEFORE INSERT OR UPDATE OF film_id, hall_id, start_time ON public.sessions FOR EACH ROW EXECUTE FUNCTION public.fn_prevent_overlapping_sessions();


--
-- TOC entry 3791 (class 2620 OID 16593)
-- Name: sessions trg_sessions_protect_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_sessions_protect_delete BEFORE DELETE ON public.sessions FOR EACH ROW EXECUTE FUNCTION public.fn_prevent_session_deletion_with_tickets();


--
-- TOC entry 3792 (class 2620 OID 16588)
-- Name: sessions trg_sessions_set_end_time; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_sessions_set_end_time BEFORE INSERT OR UPDATE OF film_id, start_time ON public.sessions FOR EACH ROW EXECUTE FUNCTION public.fn_set_session_end_time();


--
-- TOC entry 3793 (class 2620 OID 16594)
-- Name: tickets trg_tickets_block_late_cancel; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_tickets_block_late_cancel BEFORE UPDATE OF status ON public.tickets FOR EACH ROW WHEN (((new.status)::text = ANY ((ARRAY['cancelled'::character varying, 'refunded'::character varying])::text[]))) EXECUTE FUNCTION public.fn_block_late_ticket_cancellation();


--
-- TOC entry 3794 (class 2620 OID 16591)
-- Name: tickets trg_tickets_calculate_price; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_tickets_calculate_price BEFORE INSERT ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.fn_calculate_ticket_price();


--
-- TOC entry 3795 (class 2620 OID 16590)
-- Name: tickets trg_tickets_check_seat; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_tickets_check_seat BEFORE INSERT ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.fn_check_seat_availability();


--
-- TOC entry 3796 (class 2620 OID 16592)
-- Name: tickets trg_tickets_log_status; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_tickets_log_status AFTER UPDATE OF status ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.fn_log_ticket_status_change();


--
-- TOC entry 3782 (class 2606 OID 16419)
-- Name: films films_genre_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.films
    ADD CONSTRAINT films_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES public.genres(id) ON DELETE SET NULL;


--
-- TOC entry 3783 (class 2606 OID 16462)
-- Name: seats seats_hall_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seats
    ADD CONSTRAINT seats_hall_id_fkey FOREIGN KEY (hall_id) REFERENCES public.halls(id) ON DELETE CASCADE;


--
-- TOC entry 3784 (class 2606 OID 16508)
-- Name: sessions sessions_film_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_film_id_fkey FOREIGN KEY (film_id) REFERENCES public.films(id) ON DELETE CASCADE;


--
-- TOC entry 3785 (class 2606 OID 16513)
-- Name: sessions sessions_hall_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_hall_id_fkey FOREIGN KEY (hall_id) REFERENCES public.halls(id) ON DELETE CASCADE;


--
-- TOC entry 3789 (class 2606 OID 16566)
-- Name: ticket_status_log ticket_status_log_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_status_log
    ADD CONSTRAINT ticket_status_log_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON DELETE CASCADE;


--
-- TOC entry 3786 (class 2606 OID 16542)
-- Name: tickets tickets_seat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_seat_id_fkey FOREIGN KEY (seat_id) REFERENCES public.seats(id) ON DELETE CASCADE;


--
-- TOC entry 3787 (class 2606 OID 16537)
-- Name: tickets tickets_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.sessions(id) ON DELETE CASCADE;


--
-- TOC entry 3788 (class 2606 OID 16547)
-- Name: tickets tickets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


-- Completed on 2026-04-04 01:59:07 MSK

--
-- PostgreSQL database dump complete
--

\unrestrict ymPTAqav3dNVc4xDct9aZ91IiCA3vKNGY0LZmGz7gkML1e7dQkckXYS7TDs9ymn

