-- ============================================================
--  PARCHEGGI UDA — Migrazione nuove funzionalità
--  Esegui questo script sul DB esistente
-- ============================================================

-- 1. Aggiunge colonna loyalty_points agli utenti
ALTER TABLE users ADD COLUMN IF NOT EXISTS loyalty_points INTEGER DEFAULT 0;

-- 2. Aggiorna punti fedeltà esistenti basandosi sulle prenotazioni
UPDATE users u
SET loyalty_points = (
    SELECT COALESCE(SUM(b.duration_hours::INTEGER * 100), 0)
    FROM bookings b
    WHERE b.user_id = u.id AND b.status IN ('active', 'completed')
);

-- 3. Aggiunge colonna fault_report ai posti (opzionale, per tracciare segnalazioni)
ALTER TABLE parking_spots ADD COLUMN IF NOT EXISTS fault_report TEXT DEFAULT '';

-- 4. Aggiunge colonna floor_level ai posti (piano del parcheggio)
ALTER TABLE parking_spots ADD COLUMN IF NOT EXISTS floor_level INTEGER DEFAULT 1;

-- 5. Imposta floor_level in base alla zona (A=1 vicino uscita, D=4 più lontano)
UPDATE parking_spots SET floor_level = CASE zone
    WHEN 'A' THEN 1
    WHEN 'B' THEN 2
    WHEN 'C' THEN 3
    WHEN 'D' THEN 4
    ELSE 1
END;

-- 6. Aggiunge stato 'completed' ai bookings scaduti (cleanup)
UPDATE bookings SET status = 'completed'
WHERE status = 'active' AND end_time < NOW();

SELECT 'Migrazione completata!' as risultato;
