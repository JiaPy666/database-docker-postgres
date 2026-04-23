-- ============================================================
--  PARCHEGGI UDA – Schema
--  Eseguito automaticamente al primo avvio del container
-- ============================================================

-- TIPI ENUM
CREATE TYPE spot_status   AS ENUM ('free', 'occupied');
CREATE TYPE parking_type  AS ENUM ('normal', 'disabled', 'electric', 'motorcycle', 'van');
CREATE TYPE vehicle_type  AS ENUM ('car', 'motorcycle', 'van');
CREATE TYPE zone_code     AS ENUM ('A', 'B', 'C', 'D');

-- TABELLA: parking_spots
CREATE TABLE IF NOT EXISTS parking_spots (
    id              VARCHAR(4)      PRIMARY KEY,
    zone            zone_code       NOT NULL,
    status          spot_status     NOT NULL DEFAULT 'free',
    parking_type    parking_type    NOT NULL DEFAULT 'normal',
    maintenance     BOOLEAN         NOT NULL DEFAULT FALSE,
    vehicle_type    vehicle_type    NOT NULL DEFAULT 'car',
    cost            NUMERIC(5, 2)   NOT NULL CHECK (cost >= 0),
    last_updated    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_maintenance_not_occupied
        CHECK (NOT (maintenance = TRUE AND status = 'occupied'))
);

-- INDICI
CREATE INDEX idx_spots_zone         ON parking_spots (zone);
CREATE INDEX idx_spots_status       ON parking_spots (status);
CREATE INDEX idx_spots_parking_type ON parking_spots (parking_type);
CREATE INDEX idx_spots_maintenance  ON parking_spots (maintenance);
CREATE INDEX idx_spots_zone_status  ON parking_spots (zone, status);

-- VIEW: statistiche per zona
CREATE OR REPLACE VIEW v_zone_stats AS
SELECT
    zone,
    COUNT(*)                                                        AS total,
    COUNT(*) FILTER (WHERE status = 'free' AND maintenance = FALSE) AS free_spots,
    COUNT(*) FILTER (WHERE status = 'occupied')                     AS occupied_spots,
    COUNT(*) FILTER (WHERE maintenance = TRUE)                      AS maintenance_spots,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'occupied')::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE maintenance = FALSE), 0) * 100, 1
    )                                                               AS occupancy_pct,
    AVG(cost)                                                       AS avg_cost
FROM parking_spots
GROUP BY zone
ORDER BY zone;

-- VIEW: statistiche globali
CREATE OR REPLACE VIEW v_global_stats AS
SELECT
    COUNT(*)                                                        AS total,
    COUNT(*) FILTER (WHERE status = 'free' AND maintenance = FALSE) AS free_spots,
    COUNT(*) FILTER (WHERE status = 'occupied')                     AS occupied_spots,
    COUNT(*) FILTER (WHERE maintenance = TRUE)                      AS maintenance_spots,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'occupied')::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE maintenance = FALSE), 0) * 100, 1
    )                                                               AS occupancy_pct
FROM parking_spots;

-- TABELLA: users
CREATE TABLE IF NOT EXISTS users (
    id            SERIAL       PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone         VARCHAR(30)  DEFAULT '',
    plate         VARCHAR(20)  DEFAULT '',
    role          VARCHAR(20)  DEFAULT 'user'
                  CHECK (role IN ('user', 'admin')),
    created_at    TIMESTAMP    DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

-- TABELLA: bookings
CREATE TABLE IF NOT EXISTS bookings (
    id             SERIAL         PRIMARY KEY,
    booking_code   VARCHAR(20)    NOT NULL UNIQUE,
    user_id        INTEGER        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    spot_id        VARCHAR(20)    NOT NULL REFERENCES parking_spots(id),
    start_time     TIMESTAMP      NOT NULL,
    end_time       TIMESTAMP      NOT NULL,
    duration_hours NUMERIC(5,1)   NOT NULL,
    total_cost     NUMERIC(8,2)   NOT NULL,
    status         VARCHAR(20)    DEFAULT 'active'
                   CHECK (status IN ('active', 'cancelled', 'completed')),
    created_at     TIMESTAMP      DEFAULT NOW(),
    CONSTRAINT chk_times CHECK (end_time > start_time)
);

CREATE INDEX IF NOT EXISTS idx_bookings_user   ON bookings (user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_spot   ON bookings (spot_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings (status);
CREATE INDEX IF NOT EXISTS idx_bookings_code   ON bookings (booking_code);
