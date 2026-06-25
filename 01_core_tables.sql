-- Tables and sequences
-- Cinema database project. Generated from the provided PostgreSQL dump.
-- Run from repository root with: psql -d cinema_db -f scripts/restore_split.sql

CREATE TABLE public.genres (
    id integer NOT NULL,
    name character varying(80) NOT NULL
);


CREATE SEQUENCE public.genres_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.genres_id_seq OWNED BY public.genres.id;


ALTER TABLE ONLY public.genres ALTER COLUMN id SET DEFAULT nextval('public.genres_id_seq'::regclass);


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


CREATE SEQUENCE public.films_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.films_id_seq OWNED BY public.films.id;


ALTER TABLE ONLY public.films ALTER COLUMN id SET DEFAULT nextval('public.films_id_seq'::regclass);


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


CREATE SEQUENCE public.halls_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.halls_id_seq OWNED BY public.halls.id;


ALTER TABLE ONLY public.halls ALTER COLUMN id SET DEFAULT nextval('public.halls_id_seq'::regclass);


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


CREATE SEQUENCE public.seats_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.seats_id_seq OWNED BY public.seats.id;


ALTER TABLE ONLY public.seats ALTER COLUMN id SET DEFAULT nextval('public.seats_id_seq'::regclass);
