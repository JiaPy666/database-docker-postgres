-- ============================================================
--  SEED UTENTI + DATI DEMO
--  Eseguito automaticamente dopo 02_import_data.sql
-- ============================================================

-- Admin di default (password: admin123)
INSERT INTO users (name, email, password_hash, role, loyalty_points)
VALUES (
    'Amministratore',
    'admin@parcheggi-uda.it',
    encode(sha256(('parcheggi_uda_saltadmin123')::bytea), 'hex'),
    'admin',
    0
)
ON CONFLICT (email) DO NOTHING;

-- Utente demo (password: user123)
INSERT INTO users (name, email, password_hash, role, phone, plate, loyalty_points)
VALUES (
    'Mario Rossi',
    'mario@example.it',
    encode(sha256(('parcheggi_uda_saltuser123')::bytea), 'hex'),
    'user',
    '+39 333 1234567',
    'BA123AB',
    15500
)
ON CONFLICT (email) DO NOTHING;

-- ─── Turni manutenzione demo ──────────────────────────────────
INSERT INTO maintenance_schedule (zone, scheduled_date, operator, intervention_type, priority, notes, status)
VALUES
    ('A', CURRENT_DATE,         'Mario Esposito',  'Pulizia ordinaria',       'normale', 'Settore nord',       'in corso'),
    ('B', CURRENT_DATE + 1,     'Luigi Verdi',     'Controllo impianti',      'alta',    'Revisione luci',     'programmato'),
    ('C', CURRENT_DATE + 2,     'Anna Bianchi',    'Riparazione segnaletica', 'normale', '',                   'programmato'),
    ('D', CURRENT_DATE + 3,     'Carlo Neri',      'Pulizia straordinaria',   'bassa',   '',                   'programmato'),
    ('A', CURRENT_DATE - 1,     'Sara Ferrari',    'Ispezione sicurezza',     'alta',    'Completata regolare','completato')
ON CONFLICT DO NOTHING;

-- ─── Segnalazioni guasto demo ─────────────────────────────────
INSERT INTO fault_reports (spot_id, report_type, description, status)
VALUES
    ('A018', 'Illuminazione guasta',      'Lampione non funziona',          'aperta'),
    ('B042', 'Sporco/Rifiuti',            'Rifiuti abbandonati nel posto',   'in lavorazione'),
    ('C015', 'Segnaletica danneggiata',   'Cartello divelta dal vento',      'risolta')
ON CONFLICT DO NOTHING;

-- ─── Premio fedeltà demo per Mario Rossi ─────────────────────
-- (1 ora gratis disponibile = 10000 punti spesi)
INSERT INTO loyalty_rewards (user_id, points_spent, status)
SELECT id, 10000, 'available'
FROM users WHERE email = 'mario@example.it'
ON CONFLICT DO NOTHING;

-- ─── Verifica finale ──────────────────────────────────────────
SELECT 'parking_spots'        AS tabella, COUNT(*) AS righe FROM parking_spots
UNION ALL SELECT 'users',                 COUNT(*) FROM users
UNION ALL SELECT 'bookings',              COUNT(*) FROM bookings
UNION ALL SELECT 'maintenance_schedule',  COUNT(*) FROM maintenance_schedule
UNION ALL SELECT 'fault_reports',         COUNT(*) FROM fault_reports
UNION ALL SELECT 'loyalty_rewards',       COUNT(*) FROM loyalty_rewards;
