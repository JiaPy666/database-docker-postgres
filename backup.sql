--
-- PostgreSQL database dump
--

\restrict XPapyXHZsq2dFaKTNKej832oD5Ricbd9mIh8fvEhLA8AAji44g6zeHaB8gk1hYg

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
2	PRK-881EAB37	4	A001	2026-04-29 07:46:00	2026-04-29 09:46:00	2.0	3.00	cancelled	2026-04-29 07:46:42.876091
10	PRK-8C0A3DD8	4	A013	2026-04-29 08:14:00	2026-04-29 10:14:00	2.0	3.00	cancelled	2026-04-29 08:14:38.55803
12	PRK-1601AB17	5	A017	2026-04-29 08:16:00	2026-05-03 10:15:00	98.0	146.97	cancelled	2026-04-29 08:16:46.042585
13	PRK-EAF19481	5	A010	2026-04-29 10:00:00	2026-04-29 11:00:00	1.0	1.50	cancelled	2026-04-29 08:17:24.130377
14	PRK-EAF4D4C5	4	A017	2026-04-29 10:17:00	2026-05-08 10:17:00	216.0	324.00	cancelled	2026-04-29 08:17:59.372443
11	PRK-170E3B1C	4	A013	2026-04-29 10:15:00	2026-04-29 12:15:00	2.0	3.00	cancelled	2026-04-29 08:15:20.852796
9	PRK-A8CBE937	4	A011	2026-04-29 10:04:00	2026-04-29 12:04:00	2.0	2.70	cancelled	2026-04-29 08:04:36.076538
8	PRK-FCED51CC	4	A003	2026-04-30 08:03:00	2026-05-07 13:03:00	173.0	259.50	cancelled	2026-04-29 08:03:48.757268
7	PRK-B22B7567	4	A002	2026-04-29 14:02:00	2026-04-29 16:02:00	2.0	3.00	cancelled	2026-04-29 08:03:12.152457
6	PRK-B89FF84A	6	C091	2026-04-29 07:57:00	2026-04-29 09:57:00	2.0	3.00	cancelled	2026-04-29 07:57:40.08032
5	PRK-F91B1324	5	A002	2026-04-29 07:48:00	2026-04-29 13:52:00	6.1	9.10	cancelled	2026-04-29 07:48:18.676724
4	PRK-5D971EA1	4	A001	2026-04-29 09:47:00	2026-04-29 10:47:00	1.0	1.35	cancelled	2026-04-29 07:48:10.784848
15	PRK-3DA8A018	4	A010	2026-04-29 10:39:00	2026-04-29 13:39:00	3.0	4.05	cancelled	2026-04-29 08:39:45.08257
\.


--
-- Data for Name: parking_spots; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parking_spots (id, zone, status, parking_type, maintenance, vehicle_type, cost, last_updated) FROM stdin;
A002	A	free	disabled	f	car	1.50	2026-04-29 08:24:59.547133+00
B048	B	free	normal	f	car	1.50	2026-04-29 08:27:04.615179+00
C095	C	free	normal	f	car	1.50	2026-04-29 08:33:01.110334+00
B012	B	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:00.366429+00
C035	C	free	normal	f	car	1.50	2026-04-29 08:22:40.775817+00
B030	B	free	normal	f	car	1.50	2026-04-29 08:27:10.507609+00
C080	C	free	normal	f	car	1.50	2026-04-29 08:23:27.801269+00
A052	A	free	normal	f	car	1.50	2026-04-29 08:27:33.389836+00
A004	A	free	disabled	f	car	1.50	2026-04-29 08:28:59.836374+00
D022	D	free	normal	f	car	1.50	2026-04-29 08:24:10.963595+00
D036	D	free	normal	f	car	1.50	2026-04-29 08:24:30.924045+00
A017	A	free	normal	f	car	1.50	2026-04-29 08:24:36.522995+00
A003	A	free	disabled	f	car	1.50	2026-04-29 08:24:49.648499+00
A016	A	free	normal	f	car	1.50	2026-04-29 08:27:10.583916+00
A018	A	free	normal	f	car	1.50	2026-04-29 08:27:13.377883+00
A020	A	free	normal	f	car	1.50	2026-04-29 08:27:16.22167+00
A021	A	free	normal	f	car	1.50	2026-04-29 08:27:19.238643+00
A024	A	free	normal	f	car	1.50	2026-04-29 08:27:24.930637+00
A028	A	free	normal	f	car	1.50	2026-04-29 08:27:38.87447+00
A006	A	free	electric	f	car	1.50	2026-04-29 08:32:18.77513+00
A007	A	free	electric	f	car	1.50	2026-04-29 08:32:22.267343+00
A008	A	free	electric	f	car	1.50	2026-04-29 08:32:26.21201+00
A009	A	free	electric	f	car	1.50	2026-04-29 08:32:29.533614+00
A011	A	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:27.912384+00
A012	A	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:31.586+00
A013	A	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:34.598618+00
A014	A	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:37.16913+00
A015	A	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:40.617705+00
A010	A	free	electric	f	car	1.50	2026-04-29 08:40:57.590301+00
A005	A	free	disabled	f	car	1.50	2026-04-14 09:02:50+00
A019	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A022	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A023	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A025	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A026	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A027	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A029	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A030	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A031	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A048	A	free	normal	f	car	1.50	2026-04-29 08:27:52.193546+00
A033	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A034	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A049	A	free	normal	f	car	1.50	2026-04-29 08:27:55.206043+00
A037	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A038	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A039	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A041	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A060	A	free	normal	f	car	1.50	2026-04-29 08:27:59.272531+00
A043	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A045	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A046	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A056	A	free	normal	f	car	1.50	2026-04-29 08:28:02.335699+00
A050	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A051	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A063	A	free	normal	f	car	1.50	2026-04-29 08:28:06.160939+00
A053	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A054	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A055	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A057	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A058	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A059	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A061	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A062	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A065	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A066	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A067	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A069	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A071	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A073	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A074	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A075	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A078	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A079	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A081	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A082	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A083	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A085	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A086	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A087	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A089	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A090	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A093	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A094	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A095	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A097	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A099	A	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A092	A	free	normal	f	car	1.50	2026-04-29 08:28:09.580142+00
B007	B	free	electric	f	car	1.50	2026-04-14 09:02:50+00
B008	B	free	electric	f	car	1.50	2026-04-14 09:02:50+00
A064	A	free	normal	f	car	1.50	2026-04-29 08:28:10.797449+00
B010	B	free	electric	f	car	1.50	2026-04-14 09:02:50+00
A091	A	free	normal	f	car	1.50	2026-04-29 08:28:13.2748+00
B017	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A068	A	free	normal	f	car	1.50	2026-04-29 08:28:15.333804+00
B019	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B020	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A084	A	free	normal	f	car	1.50	2026-04-29 08:28:16.514465+00
B022	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B023	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A070	A	free	normal	f	car	1.50	2026-04-29 08:28:18.173118+00
B025	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B026	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A096	A	free	normal	f	car	1.50	2026-04-29 08:28:19.060369+00
B028	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B029	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A072	A	free	normal	f	car	1.50	2026-04-29 08:28:21.313229+00
B031	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B032	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
A088	A	free	normal	f	car	1.50	2026-04-29 08:28:22.352342+00
B034	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B035	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B027	B	free	normal	f	car	1.50	2026-04-29 08:27:16.098243+00
B033	B	free	normal	f	car	1.50	2026-04-29 08:27:18.923949+00
A032	A	free	normal	f	car	1.50	2026-04-29 08:27:21.659272+00
B024	B	free	normal	f	car	1.50	2026-04-29 08:27:23.154991+00
B021	B	free	normal	f	car	1.50	2026-04-29 08:27:26.548231+00
A035	A	free	normal	f	car	1.50	2026-04-29 08:27:28.337232+00
B018	B	free	normal	f	car	1.50	2026-04-29 08:27:29.517063+00
A042	A	free	normal	f	car	1.50	2026-04-29 08:27:31.02477+00
B009	B	free	electric	f	car	1.50	2026-04-29 08:27:32.518157+00
A044	A	free	normal	f	car	1.50	2026-04-29 08:27:35.566605+00
B006	B	free	electric	f	car	1.50	2026-04-29 08:27:35.737793+00
A036	A	free	normal	f	car	1.50	2026-04-29 08:27:41.531595+00
A040	A	free	normal	f	car	1.50	2026-04-29 08:27:45.47543+00
A047	A	free	normal	f	car	1.50	2026-04-29 08:27:47.902493+00
A076	A	free	normal	f	car	1.50	2026-04-29 08:28:26.092226+00
A077	A	free	normal	f	car	1.50	2026-04-29 08:28:27.633414+00
A098	A	free	normal	f	car	1.50	2026-04-29 08:28:29.374964+00
A100	A	free	normal	f	car	1.50	2026-04-29 08:28:32.131673+00
A080	A	free	normal	f	car	1.50	2026-04-29 08:28:33.126375+00
B001	B	free	disabled	f	car	1.50	2026-04-29 08:32:39.099059+00
B002	B	free	disabled	f	car	1.50	2026-04-29 08:32:42.514181+00
B003	B	free	disabled	f	car	1.50	2026-04-29 08:32:46.272491+00
B004	B	free	disabled	f	car	1.50	2026-04-29 08:32:49.089791+00
B005	B	free	disabled	f	car	1.50	2026-04-29 08:32:52.651738+00
B015	B	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:10.09835+00
B013	B	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:03.590379+00
B014	B	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:07.006755+00
B011	B	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:36:56.24894+00
B016	B	free	normal	f	car	1.50	2026-04-29 08:37:20.223697+00
C001	C	free	disabled	f	car	1.50	2026-04-29 08:33:24.605502+00
B037	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B038	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C002	C	free	disabled	f	car	1.50	2026-04-29 08:33:28.465614+00
B040	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B041	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C003	C	free	disabled	f	car	1.50	2026-04-29 08:33:32.023393+00
B043	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B044	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C004	C	free	disabled	f	car	1.50	2026-04-29 08:33:37.685993+00
B046	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B047	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C006	C	free	electric	f	car	1.50	2026-04-29 08:33:40.138488+00
B049	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B050	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C007	C	free	electric	f	car	1.50	2026-04-29 08:33:43.67443+00
B052	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B053	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C008	C	free	electric	f	car	1.50	2026-04-29 08:33:47.509516+00
B055	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B056	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C005	C	free	disabled	f	car	1.50	2026-04-29 08:33:48.379196+00
B058	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B059	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C009	C	free	electric	f	car	1.50	2026-04-29 08:33:52.744026+00
B061	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B062	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C010	C	free	electric	f	car	1.50	2026-04-29 08:33:55.634607+00
B064	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B065	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B067	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B068	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B070	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B071	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B073	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B074	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B076	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B077	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B079	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B080	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C011	C	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:06.743633+00
B082	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B083	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C012	C	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:10.347798+00
B085	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B086	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C013	C	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:13.218529+00
C014	C	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:15.736934+00
B089	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C015	C	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:18.407544+00
B091	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B092	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B094	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B095	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B097	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B098	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
B100	B	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C016	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C017	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C018	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C019	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C021	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C023	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C024	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C026	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C027	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C028	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C029	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C031	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C032	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C033	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C034	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C036	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C037	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C038	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C039	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C041	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C042	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C025	C	free	normal	f	car	1.50	2026-04-29 08:22:48.946084+00
C022	C	free	normal	f	car	1.50	2026-04-29 08:23:17.289031+00
C040	C	free	normal	f	car	1.50	2026-04-29 08:23:41.110219+00
C030	C	free	normal	f	car	1.50	2026-04-29 08:23:44.318008+00
C020	C	free	normal	f	car	1.50	2026-04-29 08:23:47.90161+00
B099	B	free	normal	f	car	1.50	2026-04-29 08:25:16.913454+00
B096	B	free	normal	f	car	1.50	2026-04-29 08:25:27.140256+00
B087	B	free	normal	f	car	1.50	2026-04-29 08:25:30.586715+00
B093	B	free	normal	f	car	1.50	2026-04-29 08:25:45.355863+00
B084	B	free	normal	f	car	1.50	2026-04-29 08:25:48.481323+00
B081	B	free	normal	f	car	1.50	2026-04-29 08:25:51.708537+00
B072	B	free	normal	f	car	1.50	2026-04-29 08:25:57.016996+00
B075	B	free	normal	f	car	1.50	2026-04-29 08:26:02.025403+00
B063	B	free	normal	f	car	1.50	2026-04-29 08:26:08.885752+00
B088	B	free	normal	f	car	1.50	2026-04-29 08:26:11.643008+00
B078	B	free	normal	f	car	1.50	2026-04-29 08:26:19.738468+00
B066	B	free	normal	f	car	1.50	2026-04-29 08:26:23.565181+00
B069	B	free	normal	f	car	1.50	2026-04-29 08:26:38.940624+00
B060	B	free	normal	f	car	1.50	2026-04-29 08:26:41.777631+00
B057	B	free	normal	f	car	1.50	2026-04-29 08:26:46.040237+00
B054	B	free	normal	f	car	1.50	2026-04-29 08:26:53.998568+00
B051	B	free	normal	f	car	1.50	2026-04-29 08:26:56.524126+00
B045	B	free	normal	f	car	1.50	2026-04-29 08:26:59.491003+00
B042	B	free	normal	f	car	1.50	2026-04-29 08:27:02.08569+00
B039	B	free	normal	f	car	1.50	2026-04-29 08:27:07.426142+00
B036	B	free	normal	f	car	1.50	2026-04-29 08:27:13.339521+00
C043	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C044	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C046	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C047	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C048	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C049	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C051	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C052	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C053	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C054	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C056	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C058	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C059	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C061	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C062	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C063	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C064	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C066	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C067	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C068	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C069	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C071	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C072	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C073	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C074	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C076	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C077	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C078	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C079	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C081	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C082	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C083	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C084	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D001	D	free	disabled	f	car	1.50	2026-04-29 08:31:31.194661+00
C086	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C087	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C088	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C089	C	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D002	D	free	disabled	f	car	1.50	2026-04-29 08:31:36.842531+00
D003	D	free	disabled	f	car	1.50	2026-04-29 08:31:40.569145+00
D004	D	free	disabled	f	car	1.50	2026-04-29 08:31:43.968792+00
D005	D	free	disabled	f	car	1.50	2026-04-29 08:31:49.574945+00
D006	D	free	electric	f	car	1.50	2026-04-29 08:32:10.58696+00
D007	D	free	electric	f	car	1.50	2026-04-29 08:32:13.891803+00
D008	D	free	electric	f	car	1.50	2026-04-29 08:32:17.36972+00
D009	D	free	electric	f	car	1.50	2026-04-29 08:32:20.736028+00
D010	D	free	electric	f	car	1.50	2026-04-29 08:32:24.709923+00
C091	C	free	normal	f	car	1.50	2026-04-29 08:32:39.099089+00
C093	C	free	normal	f	car	1.50	2026-04-29 08:32:51.637474+00
C092	C	free	normal	f	car	1.50	2026-04-29 08:32:48.342174+00
D017	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C094	C	free	normal	f	car	1.50	2026-04-29 08:32:55.159632+00
D019	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C096	C	free	normal	f	car	1.50	2026-04-29 08:33:04.201312+00
D021	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D023	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C097	C	free	normal	f	car	1.50	2026-04-29 08:33:07.313506+00
D025	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C098	C	free	normal	f	car	1.50	2026-04-29 08:33:12.525421+00
C099	C	free	normal	f	car	1.50	2026-04-29 08:33:16.374577+00
C100	C	free	normal	f	car	1.50	2026-04-29 08:33:19.326947+00
D029	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D031	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D033	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D037	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D011	D	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:23.084629+00
D039	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D012	D	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:26.382774+00
D041	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D013	D	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:29.491916+00
D043	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D014	D	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:32.330942+00
D015	D	free	motorcycle	f	motorcycle	1.50	2026-04-29 08:37:38.572965+00
D047	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D049	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
C085	C	free	normal	f	car	1.50	2026-04-29 08:21:50.096121+00
C075	C	free	normal	f	car	1.50	2026-04-29 08:21:53.303912+00
C065	C	free	normal	f	car	1.50	2026-04-29 08:21:57.34314+00
C055	C	free	normal	f	car	1.50	2026-04-29 08:22:31.916696+00
C045	C	free	normal	f	car	1.50	2026-04-29 08:22:35.57979+00
C057	C	free	normal	f	car	1.50	2026-04-29 08:23:12.603541+00
C090	C	free	normal	f	car	1.50	2026-04-29 08:23:24.840484+00
C070	C	free	normal	f	car	1.50	2026-04-29 08:23:30.390347+00
C060	C	free	normal	f	car	1.50	2026-04-29 08:23:33.980853+00
C050	C	free	normal	f	car	1.50	2026-04-29 08:23:37.471374+00
D018	D	free	normal	f	car	1.50	2026-04-29 08:23:45.087222+00
D016	D	free	normal	f	car	1.50	2026-04-29 08:23:47.500685+00
D020	D	free	normal	f	car	1.50	2026-04-29 08:24:05.839654+00
D032	D	free	normal	f	car	1.50	2026-04-29 08:24:14.425726+00
D024	D	free	normal	f	car	1.50	2026-04-29 08:24:17.102996+00
D034	D	free	normal	f	car	1.50	2026-04-29 08:24:19.668547+00
D035	D	free	normal	f	car	1.50	2026-04-29 08:24:23.221774+00
D026	D	free	normal	f	car	1.50	2026-04-29 08:24:28.089379+00
D027	D	free	normal	f	car	1.50	2026-04-29 08:24:34.369991+00
D028	D	free	normal	f	car	1.50	2026-04-29 08:24:37.986558+00
D038	D	free	normal	f	car	1.50	2026-04-29 08:24:42.424454+00
D030	D	free	normal	f	car	1.50	2026-04-29 08:24:45.189191+00
D040	D	free	normal	f	car	1.50	2026-04-29 08:24:47.928652+00
D042	D	free	normal	f	car	1.50	2026-04-29 08:24:52.953351+00
D044	D	free	normal	f	car	1.50	2026-04-29 08:25:19.395659+00
D045	D	free	normal	f	car	1.50	2026-04-29 08:25:25.904268+00
D046	D	free	normal	f	car	1.50	2026-04-29 08:25:44.965723+00
D048	D	free	normal	f	car	1.50	2026-04-29 08:26:04.316589+00
D050	D	free	normal	f	car	1.50	2026-04-29 08:26:07.430208+00
D051	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D053	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D055	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D057	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D059	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D061	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D065	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D067	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D069	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D071	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D073	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D075	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D077	D	free	normal	f	car	1.50	2026-04-14 09:02:50+00
D083	D	free	van	f	van	1.50	2026-04-14 09:02:50+00
D085	D	free	van	f	van	1.50	2026-04-14 09:02:50+00
D087	D	free	van	f	van	1.50	2026-04-14 09:02:50+00
D089	D	free	van	f	van	1.50	2026-04-14 09:02:50+00
D091	D	free	van	f	van	1.50	2026-04-14 09:02:50+00
D093	D	free	van	f	van	1.50	2026-04-14 09:02:50+00
D095	D	free	van	f	van	1.50	2026-04-14 09:02:50+00
D097	D	free	van	f	van	1.50	2026-04-14 09:02:50+00
D052	D	free	normal	f	car	1.50	2026-04-29 08:24:56.387498+00
D062	D	free	normal	f	car	1.50	2026-04-29 08:24:59.516299+00
D072	D	free	normal	f	car	1.50	2026-04-29 08:25:02.398435+00
A001	A	free	disabled	f	car	1.50	2026-04-29 08:25:02.477127+00
D081	D	free	van	f	van	1.50	2026-04-29 08:25:05.258964+00
D082	D	free	van	f	van	1.50	2026-04-29 08:25:08.002358+00
D092	D	free	van	f	van	1.50	2026-04-29 08:25:10.552677+00
D063	D	free	normal	f	car	1.50	2026-04-29 08:25:13.264885+00
D064	D	free	normal	f	car	1.50	2026-04-29 08:25:16.210962+00
D054	D	free	normal	f	car	1.50	2026-04-29 08:25:22.183443+00
B090	B	free	normal	f	car	1.50	2026-04-29 08:25:22.91211+00
D074	D	free	normal	f	car	1.50	2026-04-29 08:25:28.936411+00
D084	D	free	van	f	van	1.50	2026-04-29 08:25:31.33306+00
D094	D	free	van	f	van	1.50	2026-04-29 08:25:34.006349+00
D056	D	free	normal	f	car	1.50	2026-04-29 08:25:48.715401+00
D066	D	free	normal	f	car	1.50	2026-04-29 08:25:51.444987+00
D076	D	free	normal	f	car	1.50	2026-04-29 08:25:54.281637+00
D086	D	free	van	f	van	1.50	2026-04-29 08:25:56.770829+00
D096	D	free	van	f	van	1.50	2026-04-29 08:26:00.137732+00
D058	D	free	normal	f	car	1.50	2026-04-29 08:26:10.179364+00
D060	D	free	normal	f	car	1.50	2026-04-29 08:26:12.774638+00
D068	D	free	normal	f	car	1.50	2026-04-29 08:26:16.24786+00
D078	D	free	normal	f	car	1.50	2026-04-29 08:26:19.047995+00
D079	D	free	normal	f	car	1.50	2026-04-29 08:26:22.270068+00
D070	D	free	normal	f	car	1.50	2026-04-29 08:26:24.929249+00
D080	D	free	normal	f	car	1.50	2026-04-29 08:26:28.291401+00
D088	D	free	van	f	van	1.50	2026-04-29 08:26:31.122726+00
D098	D	free	van	f	van	1.50	2026-04-29 08:26:34.151958+00
D099	D	free	van	f	van	1.50	2026-04-29 08:26:37.625088+00
D090	D	free	van	f	van	1.50	2026-04-29 08:26:40.703834+00
D100	D	free	van	f	van	1.50	2026-04-29 08:26:43.63322+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email, password_hash, phone, plate, role, created_at) FROM stdin;
1	Amministratore	admin@parcheggi-uda.it	74a437c9cc0298672562cff2236b2c696cee509d25f9bde61ee6218237b54291			admin	2026-04-24 09:00:20.099883
4	souhel	123@gmail.com	e7d92a2f0ee1b34575751640a825b3f78917e9a98d5698040d153101bbb43282	1234567	ad234dd	user	2026-04-29 07:46:36.474522
5	filo	parmij@gmail.com	a6f0b56307cae2f7e4848b14b004154b2698f75261a9c82016cd3151a0462d63		aa123rr	user	2026-04-29 07:48:08.690373
6	Cristian Loda	cristianloda2007@gmail.com	f118a18af3090ed665ae34bb900df823993550e25d7b0289d4867805754efc14	333456987	AX123QW	user	2026-04-29 07:57:19.293578
7	bho	bho@parcheggi.it	2ddd0e2d0f805cc1454c2bf12148df7a3bf6c7c8a2429f3db8ce52db09f4b70d	123465	sad12	user	2026-04-29 08:28:20.462119
\.


--
-- Name: bookings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.bookings_id_seq', 15, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 7, true);


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

\unrestrict XPapyXHZsq2dFaKTNKej832oD5Ricbd9mIh8fvEhLA8AAji44g6zeHaB8gk1hYg

