-- ============================================================
--  PARCHEGGI UDA – Schema completo aggiornato
--  Eseguito automaticamente al primo avvio del container
-- ============================================================

-- TIPI ENUM
CREATE TYPE spot_status   AS ENUM ('free', 'occupied');
CREATE TYPE parking_type  AS ENUM ('normal', 'disabled', 'electric', 'motorcycle', 'van');
CREATE TYPE vehicle_type  AS ENUM ('car', 'motorcycle', 'van');
CREATE TYPE zone_code     AS ENUM ('A', 'B', 'C', 'D');

-- ─── TABELLA: parking_spots ────────────────────────────────────
CREATE TABLE IF NOT EXISTS parking_spots (
    id              VARCHAR(4)      PRIMARY KEY,
    zone            zone_code       NOT NULL,
    status          spot_status     NOT NULL DEFAULT 'free',
    parking_type    parking_type    NOT NULL DEFAULT 'normal',
    maintenance     BOOLEAN         NOT NULL DEFAULT FALSE,
    vehicle_type    vehicle_type    NOT NULL DEFAULT 'car',
    cost            NUMERIC(5,2)    NOT NULL CHECK (cost >= 0),
    floor_level     INTEGER         NOT NULL DEFAULT 1,
    fault_report    TEXT            DEFAULT '',
    last_updated    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_maintenance_not_occupied
        CHECK (NOT (maintenance = TRUE AND status = 'occupied'))
);

CREATE INDEX IF NOT EXISTS idx_spots_zone         ON parking_spots (zone);
CREATE INDEX IF NOT EXISTS idx_spots_status       ON parking_spots (status);
CREATE INDEX IF NOT EXISTS idx_spots_parking_type ON parking_spots (parking_type);
CREATE INDEX IF NOT EXISTS idx_spots_maintenance  ON parking_spots (maintenance);
CREATE INDEX IF NOT EXISTS idx_spots_zone_status  ON parking_spots (zone, status);

-- ─── VIEW: statistiche per zona ───────────────────────────────
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

-- ─── VIEW: statistiche globali ────────────────────────────────
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

-- ─── TABELLA: users ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id              SERIAL          PRIMARY KEY,
    name            VARCHAR(100)    NOT NULL,
    email           VARCHAR(150)    NOT NULL UNIQUE,
    password_hash   VARCHAR(255)    NOT NULL,
    phone           VARCHAR(30)     DEFAULT '',
    plate           VARCHAR(20)     DEFAULT '',
    role            VARCHAR(20)     DEFAULT 'user'
                    CHECK (role IN ('user', 'admin')),
    loyalty_points  INTEGER         NOT NULL DEFAULT 0,
    created_at      TIMESTAMP       DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

-- ─── TABELLA: bookings ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bookings (
    id              SERIAL          PRIMARY KEY,
    booking_code    VARCHAR(20)     NOT NULL UNIQUE,
    user_id         INTEGER         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    spot_id         VARCHAR(20)     NOT NULL REFERENCES parking_spots(id),
    start_time      TIMESTAMP       NOT NULL,
    end_time        TIMESTAMP       NOT NULL,
    duration_hours  NUMERIC(5,1)    NOT NULL,
    total_cost      NUMERIC(8,2)    NOT NULL,
    free_hour_used  BOOLEAN         NOT NULL DEFAULT FALSE,
    status          VARCHAR(20)     DEFAULT 'active'
                    CHECK (status IN ('active', 'cancelled', 'completed')),
    created_at      TIMESTAMP       DEFAULT NOW(),
    CONSTRAINT chk_times CHECK (end_time > start_time)
);

CREATE INDEX IF NOT EXISTS idx_bookings_user   ON bookings (user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_spot   ON bookings (spot_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings (status);
CREATE INDEX IF NOT EXISTS idx_bookings_code   ON bookings (booking_code);

-- ─── TABELLA: loyalty_rewards ─────────────────────────────────
-- Tiene traccia di ogni riscatto di ora gratis
CREATE TABLE IF NOT EXISTS loyalty_rewards (
    id              SERIAL          PRIMARY KEY,
    user_id         INTEGER         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    points_spent    INTEGER         NOT NULL DEFAULT 10000,
    status          VARCHAR(20)     NOT NULL DEFAULT 'available'
                    CHECK (status IN ('available', 'used', 'expired')),
    booking_id      INTEGER         REFERENCES bookings(id) ON DELETE SET NULL,
    created_at      TIMESTAMP       DEFAULT NOW(),
    used_at         TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_rewards_user   ON loyalty_rewards (user_id);
CREATE INDEX IF NOT EXISTS idx_rewards_status ON loyalty_rewards (status);

-- ─── TABELLA: fault_reports ───────────────────────────────────
-- Segnalazioni guasto/sporco inviate dagli utenti
CREATE TABLE IF NOT EXISTS fault_reports (
    id              SERIAL          PRIMARY KEY,
    spot_id         VARCHAR(20)     NOT NULL REFERENCES parking_spots(id),
    user_id         INTEGER         REFERENCES users(id) ON DELETE SET NULL,
    report_type     VARCHAR(50)     NOT NULL DEFAULT 'Altro',
    description     TEXT            DEFAULT '',
    status          VARCHAR(20)     NOT NULL DEFAULT 'aperta'
                    CHECK (status IN ('aperta', 'in lavorazione', 'risolta')),
    created_at      TIMESTAMP       DEFAULT NOW(),
    resolved_at     TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_fault_spot   ON fault_reports (spot_id);
CREATE INDEX IF NOT EXISTS idx_fault_status ON fault_reports (status);
CREATE INDEX IF NOT EXISTS idx_fault_user   ON fault_reports (user_id);

-- ─── TABELLA: maintenance_schedule ───────────────────────────
-- Turni di manutenzione pianificati dagli admin
CREATE TABLE IF NOT EXISTS maintenance_schedule (
    id              SERIAL          PRIMARY KEY,
    zone            zone_code       NOT NULL,
    scheduled_date  DATE            NOT NULL,
    operator        VARCHAR(100)    NOT NULL,
    intervention_type VARCHAR(100)  NOT NULL DEFAULT 'Pulizia ordinaria',
    priority        VARCHAR(20)     NOT NULL DEFAULT 'normale'
                    CHECK (priority IN ('bassa', 'normale', 'alta')),
    notes           TEXT            DEFAULT '',
    status          VARCHAR(30)     NOT NULL DEFAULT 'programmato'
                    CHECK (status IN ('programmato', 'in corso', 'completato', 'annullato')),
    created_by      INTEGER         REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMP       DEFAULT NOW(),
    updated_at      TIMESTAMP       DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_maint_zone   ON maintenance_schedule (zone);
CREATE INDEX IF NOT EXISTS idx_maint_date   ON maintenance_schedule (scheduled_date);
CREATE INDEX IF NOT EXISTS idx_maint_status ON maintenance_schedule (status);

-- ─── VIEW: segnalazioni aperte per zona ───────────────────────
CREATE OR REPLACE VIEW v_open_faults AS
SELECT
    ps.zone,
    COUNT(fr.id)    AS open_faults,
    STRING_AGG(fr.spot_id, ', ' ORDER BY fr.spot_id) AS spots_with_faults
FROM fault_reports fr
JOIN parking_spots ps ON fr.spot_id = ps.id
WHERE fr.status != 'risolta'
GROUP BY ps.zone
ORDER BY ps.zone;
