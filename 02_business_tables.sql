-- Tables and sequences
-- Cinema database project. Generated from the provided PostgreSQL dump.
-- Run from repository root with: psql -d cinema_db -f scripts/restore_split.sql

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


CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


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


CREATE SEQUENCE public.sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


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


CREATE SEQUENCE public.tickets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.tickets_id_seq OWNED BY public.tickets.id;


ALTER TABLE ONLY public.tickets ALTER COLUMN id SET DEFAULT nextval('public.tickets_id_seq'::regclass);


CREATE TABLE public.ticket_status_log (
    id integer NOT NULL,
    ticket_id integer NOT NULL,
    old_status character varying(20),
    new_status character varying(20) NOT NULL,
    changed_at timestamp without time zone DEFAULT now() NOT NULL,
    changed_by character varying(100) DEFAULT CURRENT_USER NOT NULL
);


CREATE SEQUENCE public.ticket_status_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.ticket_status_log_id_seq OWNED BY public.ticket_status_log.id;


ALTER TABLE ONLY public.ticket_status_log ALTER COLUMN id SET DEFAULT nextval('public.ticket_status_log_id_seq'::regclass);
