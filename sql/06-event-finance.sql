-- ============================================
-- MIGRATION: Aggiunge campi evento alle transazioni
-- Data: 2026-01-28
-- ============================================

-- Aggiungi colonne per collegare transazioni ad eventi
DO $$
BEGIN
    -- Aggiungi event_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'transactions' AND column_name = 'event_id'
    ) THEN
        ALTER TABLE transactions ADD COLUMN event_id TEXT;
        COMMENT ON COLUMN transactions.event_id IS 'ID evento Google Calendar o locale';
    END IF;

    -- Aggiungi event_name
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'transactions' AND column_name = 'event_name'
    ) THEN
        ALTER TABLE transactions ADD COLUMN event_name TEXT;
        COMMENT ON COLUMN transactions.event_name IS 'Nome evento per riferimento rapido';
    END IF;

    -- Aggiungi is_event_transaction flag
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'transactions' AND column_name = 'is_event_transaction'
    ) THEN
        ALTER TABLE transactions ADD COLUMN is_event_transaction BOOLEAN DEFAULT FALSE;
        COMMENT ON COLUMN transactions.is_event_transaction IS 'True se transazione legata a evento';
    END IF;
END $$;

-- Indice per query eventi
CREATE INDEX IF NOT EXISTS idx_transactions_event ON transactions(event_id);
CREATE INDEX IF NOT EXISTS idx_transactions_event_flag ON transactions(is_event_transaction) WHERE is_event_transaction = TRUE;

-- Commenti
COMMENT ON TABLE transactions IS 'Transazioni finanziarie con supporto eventi';
