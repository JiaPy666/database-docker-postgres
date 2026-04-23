-- ============================================================
--  SEED UTENTI – Admin di default
--  Password: "admin123"  →  cambiala dopo il primo login!
-- ============================================================

INSERT INTO users (name, email, password_hash, role)
VALUES (
    'Amministratore',
    'admin@parcheggi-uda.it',
    encode(sha256(('parcheggi_uda_saltadmin123')::bytea), 'hex'),
    'admin'
)
ON CONFLICT (email) DO NOTHING;

-- Verifica finale
SELECT 'parking_spots' AS tabella, COUNT(*) AS righe FROM parking_spots
UNION ALL
SELECT 'users',    COUNT(*) FROM users
UNION ALL
SELECT 'bookings', COUNT(*) FROM bookings;
