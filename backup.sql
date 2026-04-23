--
-- PostgreSQL database dump
--

\restrict mZwNCbLS34WXElddmwgHOq9QrMNkIXijCo2R7lDbLmffVwOknd1M3kKP7HmgBOR

-- Dumped from database version 16.13 (Debian 16.13-1.pgdg13+1)
-- Dumped by pg_dump version 16.13 (Debian 16.13-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: parking_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.parking_type AS ENUM (
    'normal',
    'disabled',
    'electric',
    'motorcycle',
    'van'
);


ALTER TYPE public.parking_type OWNER TO postgres;

--
-- Name: spot_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.spot_status AS ENUM (
    'free',
    'occupied'
);


ALTER TYPE public.spot_status OWNER TO postgres;

--
-- Name: vehicle_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.vehicle_type AS ENUM (
    'car',
    'motorcycle',
    'van'
);


ALTER TYPE public.vehicle_type OWNER TO postgres;

--
-- Name: zone_code; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.zone_code AS ENUM (
    'A',
    'B',
    'C',
    'D'
);


ALTER TYPE public.zone_code OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bookings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bookings (
    id integer NOT NULL,
    booking_code character varying(20) NOT NULL,
    user_id integer NOT NULL,
    spot_id character varying(20) NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    duration_hours numeric(5,1) NOT NULL,
    total_cost numeric(8,2) NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT bookings_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'cancelled'::character varying, 'completed'::character varying])::text[]))),
    CONSTRAINT chk_times CHECK ((end_time > start_time))
);


ALTER TABLE public.bookings OWNER TO postgres;

--
-- Name: bookings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bookings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bookings_id_seq OWNER TO postgres;

--
-- Name: bookings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bookings_id_seq OWNED BY public.bookings.id;


--
-- Name: parking_spots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parking_spots (
    id character varying(4) NOT NULL,
    zone public.zone_code NOT NULL,
    status public.spot_status DEFAULT 'free'::public.spot_status NOT NULL,
    parking_type public.parking_type DEFAULT 'normal'::public.parking_type NOT NULL,
    maintenance boolean DEFAULT false NOT NULL,
    vehicle_type public.vehicle_type DEFAULT 'car'::public.vehicle_type NOT NULL,
    cost numeric(5,2) NOT NULL,
    last_updated timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_maintenance_not_occupied CHECK ((NOT ((maintenance = true) AND (status = 'occupied'::public.spot_status)))),
    CONSTRAINT parking_spots_cost_check CHECK ((cost >= (0)::numeric))
);


ALTER TABLE public.parking_spots OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    password_hash character varying(255) NOT NULL,
    phone character varying(30) DEFAULT ''::character varying,
    plate character varying(20) DEFAULT ''::character varying,
    role character varying(20) DEFAULT 'user'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['user'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
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
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: v_global_stats; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_global_stats AS
 SELECT count(*) AS total,
    count(*) FILTER (WHERE ((status = 'free'::public.spot_status) AND (maintenance = false))) AS free_spots,
    count(*) FILTER (WHERE (status = 'occupied'::public.spot_status)) AS occupied_spots,
    count(*) FILTER (WHERE (maintenance = true)) AS maintenance_spots,
    round((((count(*) FILTER (WHERE (status = 'occupied'::public.spot_status)))::numeric / (NULLIF(count(*) FILTER (WHERE (maintenance = false)), 0))::numeric) * (100)::numeric), 1) AS occupancy_pct
   FROM public.parking_spots;


ALTER VIEW public.v_global_stats OWNER TO postgres;

--
-- Name: v_zone_stats; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_zone_stats AS
 SELECT zone,
    count(*) AS total,
    count(*) FILTER (WHERE ((status = 'free'::public.spot_status) AND (maintenance = false))) AS free_spots,
    count(*) FILTER (WHERE (status = 'occupied'::public.spot_status)) AS occupied_spots,
    count(*) FILTER (WHERE (maintenance = true)) AS maintenance_spots,
    round((((count(*) FILTER (WHERE (status = 'occupied'::public.spot_status)))::numeric / (NULLIF(count(*) FILTER (WHERE (maintenance = false)), 0))::numeric) * (100)::numeric), 1) AS occupancy_pct,
    avg(cost) AS avg_cost
   FROM public.parking_spots
  GROUP BY zone
  ORDER BY zone;


ALTER VIEW public.v_zone_stats OWNER TO postgres;

--
-- Name: bookings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings ALTER COLUMN id SET DEFAULT nextval('public.bookings_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: bookings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bookings (id, booking_code, user_id, spot_id, start_time, end_time, duration_hours, total_cost, status, created_at) FROM stdin;
\.


--
-- Data for Name: parking_spots; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parking_spots (id, zone, status, parking_type, maintenance, vehicle_type, cost, last_updated) FROM stdin;
A001	A	free	disabled	f	car	4.50	2026-04-14 09:02:50+00
A002	A	free	disabled	f	car	4.50	2026-04-14 09:02:50+00
A003	A	free	disabled	f	car	4.50	2026-04-14 09:02:50+00
A004	A	occupied	disabled	f	car	4.50	2026-04-14 09:02:50+00
A005	A	free	disabled	f	car	4.50	2026-04-14 09:02:50+00
A006	A	free	disabled	f	car	4.50	2026-04-14 09:02:50+00
A007	A	occupied	disabled	f	car	4.50	2026-04-14 09:02:50+00
A008	A	occupied	disabled	f	car	4.50	2026-04-14 09:02:50+00
A009	A	free	disabled	f	car	4.50	2026-04-14 09:02:50+00
A010	A	free	disabled	f	car	4.50	2026-04-14 09:02:50+00
A011	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A012	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A013	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A014	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A015	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A016	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A017	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A018	A	free	normal	t	car	6.50	2026-04-14 09:02:50+00
A019	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A020	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A021	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A022	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A023	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A024	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A025	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A026	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A027	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A028	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A029	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A030	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A031	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A032	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A033	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A034	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A035	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A036	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A037	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A038	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A039	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A040	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A041	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A042	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A043	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A044	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A045	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A046	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A047	A	free	normal	t	car	6.50	2026-04-14 09:02:50+00
A048	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A049	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A050	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A051	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A052	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A053	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A054	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A055	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A056	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A057	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A058	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A059	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A060	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A061	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A062	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A063	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A064	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A065	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A066	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A067	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A068	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A069	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A070	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A071	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A072	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A073	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A074	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A075	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A076	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A077	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A078	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A079	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A080	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A081	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A082	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A083	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A084	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A085	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A086	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A087	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A088	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A089	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A090	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A091	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A092	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A093	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A094	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A095	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A096	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A097	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A098	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
A099	A	free	normal	f	car	6.50	2026-04-14 09:02:50+00
A100	A	occupied	normal	f	car	6.50	2026-04-14 09:02:50+00
B001	B	free	electric	f	car	6.50	2026-04-14 09:02:50+00
B002	B	free	electric	f	car	6.50	2026-04-14 09:02:50+00
B003	B	occupied	electric	f	car	6.50	2026-04-14 09:02:50+00
B004	B	free	electric	f	car	6.50	2026-04-14 09:02:50+00
B005	B	free	electric	f	car	6.50	2026-04-14 09:02:50+00
B006	B	occupied	electric	f	car	6.50	2026-04-14 09:02:50+00
B007	B	free	electric	f	car	6.50	2026-04-14 09:02:50+00
B008	B	free	electric	f	car	6.50	2026-04-14 09:02:50+00
B009	B	occupied	electric	f	car	6.50	2026-04-14 09:02:50+00
B010	B	free	electric	f	car	6.50	2026-04-14 09:02:50+00
B011	B	free	electric	f	car	6.50	2026-04-14 09:02:50+00
B012	B	occupied	electric	f	car	6.50	2026-04-14 09:02:50+00
B013	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B014	B	free	normal	t	car	5.00	2026-04-14 09:02:50+00
B015	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B016	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B017	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B018	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B019	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B020	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B021	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B022	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B023	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B024	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B025	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B026	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B027	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B028	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B029	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B030	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B031	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B032	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B033	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B034	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B035	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B036	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B037	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B038	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B039	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B040	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B041	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B042	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B043	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B044	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B045	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B046	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B047	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B048	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B049	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B050	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B051	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B052	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B053	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B054	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B055	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B056	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B057	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B058	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B059	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B060	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B061	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B062	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B063	B	free	normal	t	car	5.00	2026-04-14 09:02:50+00
B064	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B065	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B066	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B067	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B068	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B069	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B070	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B071	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B072	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B073	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B074	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B075	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B076	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B077	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B078	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B079	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B080	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B081	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B082	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B083	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B084	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B085	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B086	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B087	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B088	B	free	normal	t	car	5.00	2026-04-14 09:02:50+00
B089	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B090	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B091	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B092	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B093	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B094	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B095	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B096	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B097	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B098	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
B099	B	occupied	normal	f	car	5.00	2026-04-14 09:02:50+00
B100	B	free	normal	f	car	5.00	2026-04-14 09:02:50+00
C001	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C002	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C003	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C004	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C005	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C006	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C007	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C008	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C009	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C010	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C011	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C012	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C013	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C014	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C015	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C016	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C017	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C018	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C019	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C020	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C021	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C022	C	free	normal	t	car	3.50	2026-04-14 09:02:50+00
C023	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C024	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C025	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C026	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C027	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C028	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C029	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C030	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C031	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C032	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C033	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C034	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C035	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C036	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C037	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C038	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C039	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C040	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C041	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C042	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C043	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C044	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C045	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C046	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C047	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C048	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C049	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C050	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C051	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C052	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C053	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C054	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C055	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C056	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C057	C	free	normal	t	car	3.50	2026-04-14 09:02:50+00
C058	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C059	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C060	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C061	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C062	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C063	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C064	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C065	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C066	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C067	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C068	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C069	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C070	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C071	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C072	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C073	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C074	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C075	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C076	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C077	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C078	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C079	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C080	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C081	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C082	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C083	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C084	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C085	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C086	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C087	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C088	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C089	C	free	normal	f	car	3.50	2026-04-14 09:02:50+00
C090	C	occupied	normal	f	car	3.50	2026-04-14 09:02:50+00
C091	C	free	motorcycle	f	motorcycle	2.00	2026-04-14 09:02:50+00
C092	C	free	motorcycle	f	motorcycle	2.00	2026-04-14 09:02:50+00
C093	C	free	motorcycle	f	motorcycle	2.00	2026-04-14 09:02:50+00
C094	C	free	motorcycle	f	motorcycle	2.00	2026-04-14 09:02:50+00
C095	C	occupied	motorcycle	f	motorcycle	2.00	2026-04-14 09:02:50+00
C096	C	free	motorcycle	f	motorcycle	2.00	2026-04-14 09:02:50+00
C097	C	free	motorcycle	f	motorcycle	2.00	2026-04-14 09:02:50+00
C098	C	free	motorcycle	f	motorcycle	2.00	2026-04-14 09:02:50+00
C099	C	free	motorcycle	f	motorcycle	2.00	2026-04-14 09:02:50+00
C100	C	occupied	motorcycle	f	motorcycle	2.00	2026-04-14 09:02:50+00
D001	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D002	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D003	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D004	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D005	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D006	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D007	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D008	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D009	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D010	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D011	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D012	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D013	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D014	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D015	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D016	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D017	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D018	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D019	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D020	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D021	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D022	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D023	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D024	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D025	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D026	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D027	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D028	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D029	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D030	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D031	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D032	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D033	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D034	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D035	D	free	normal	t	car	2.50	2026-04-14 09:02:50+00
D036	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D037	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D038	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D039	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D040	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D041	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D042	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D043	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D044	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D045	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D046	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D047	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D048	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D049	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D050	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D051	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D052	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D053	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D054	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D055	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D056	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D057	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D058	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D059	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D060	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D061	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D062	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D063	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D064	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D065	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D066	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D067	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D068	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D069	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D070	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D071	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D072	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D073	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D074	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D075	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D076	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D077	D	free	normal	f	car	2.50	2026-04-14 09:02:50+00
D078	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D079	D	free	normal	t	car	2.50	2026-04-14 09:02:50+00
D080	D	occupied	normal	f	car	2.50	2026-04-14 09:02:50+00
D081	D	occupied	van	f	van	4.50	2026-04-14 09:02:50+00
D082	D	occupied	van	f	van	4.50	2026-04-14 09:02:50+00
D083	D	free	van	f	van	4.50	2026-04-14 09:02:50+00
D084	D	occupied	van	f	van	4.50	2026-04-14 09:02:50+00
D085	D	free	van	f	van	4.50	2026-04-14 09:02:50+00
D086	D	occupied	van	f	van	4.50	2026-04-14 09:02:50+00
D087	D	free	van	f	van	4.50	2026-04-14 09:02:50+00
D088	D	occupied	van	f	van	4.50	2026-04-14 09:02:50+00
D089	D	free	van	f	van	4.50	2026-04-14 09:02:50+00
D090	D	occupied	van	f	van	4.50	2026-04-14 09:02:50+00
D091	D	free	van	f	van	4.50	2026-04-14 09:02:50+00
D092	D	occupied	van	f	van	4.50	2026-04-14 09:02:50+00
D093	D	free	van	f	van	4.50	2026-04-14 09:02:50+00
D094	D	occupied	van	f	van	4.50	2026-04-14 09:02:50+00
D095	D	free	van	f	van	4.50	2026-04-14 09:02:50+00
D096	D	free	van	t	van	4.50	2026-04-14 09:02:50+00
D097	D	free	van	f	van	4.50	2026-04-14 09:02:50+00
D098	D	occupied	van	f	van	4.50	2026-04-14 09:02:50+00
D099	D	occupied	van	f	van	4.50	2026-04-14 09:02:50+00
D100	D	occupied	van	f	van	4.50	2026-04-14 09:02:50+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email, password_hash, phone, plate, role, created_at) FROM stdin;
1	Amministratore	admin@parcheggi-uda.it	74a437c9cc0298672562cff2236b2c696cee509d25f9bde61ee6218237b54291			admin	2026-04-23 19:10:28.225563
\.


--
-- Name: bookings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.bookings_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 1, true);


--
-- Name: bookings bookings_booking_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_booking_code_key UNIQUE (booking_code);


--
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- Name: parking_spots parking_spots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_spots
    ADD CONSTRAINT parking_spots_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_bookings_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_code ON public.bookings USING btree (booking_code);


--
-- Name: idx_bookings_spot; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_spot ON public.bookings USING btree (spot_id);


--
-- Name: idx_bookings_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_status ON public.bookings USING btree (status);


--
-- Name: idx_bookings_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_user ON public.bookings USING btree (user_id);


--
-- Name: idx_spots_maintenance; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_spots_maintenance ON public.parking_spots USING btree (maintenance);


--
-- Name: idx_spots_parking_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_spots_parking_type ON public.parking_spots USING btree (parking_type);


--
-- Name: idx_spots_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_spots_status ON public.parking_spots USING btree (status);


--
-- Name: idx_spots_zone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_spots_zone ON public.parking_spots USING btree (zone);


--
-- Name: idx_spots_zone_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_spots_zone_status ON public.parking_spots USING btree (zone, status);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: bookings bookings_spot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_spot_id_fkey FOREIGN KEY (spot_id) REFERENCES public.parking_spots(id);


--
-- Name: bookings bookings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict mZwNCbLS34WXElddmwgHOq9QrMNkIXijCo2R7lDbLmffVwOknd1M3kKP7HmgBOR

