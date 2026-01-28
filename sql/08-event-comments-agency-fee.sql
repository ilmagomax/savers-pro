-- ============================================
-- MIGRATION: Aggiunge campi compensi agenzia a event_comments
-- Data: 2026-01-28
-- ============================================

-- Aggiungi colonne per sistema incasso/guadagno/compensi
DO $$
BEGIN
    -- Incasso totale evento
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'event_comments' AND column_name = 'income_total'
    ) THEN
        ALTER TABLE event_comments ADD COLUMN income_total DECIMAL(12,2);
        COMMENT ON COLUMN event_comments.income_total IS 'Incasso totale ricevuto dall''evento';
    END IF;

    -- Guadagno animatore
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'event_comments' AND column_name = 'animator_profit'
    ) THEN
        ALTER TABLE event_comments ADD COLUMN animator_profit DECIMAL(12,2);
        COMMENT ON COLUMN event_comments.animator_profit IS 'Guadagno che spetta all''animatore';
    END IF;

    -- Spese sostenute
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'event_comments' AND column_name = 'animator_expenses'
    ) THEN
        ALTER TABLE event_comments ADD COLUMN animator_expenses DECIMAL(12,2) DEFAULT 0;
        COMMENT ON COLUMN event_comments.animator_expenses IS 'Spese sostenute dall''animatore';
    END IF;

    -- Compensi agenzia (calcolato: income_total - animator_profit - animator_expenses)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'event_comments' AND column_name = 'agency_fee'
    ) THEN
        ALTER TABLE event_comments ADD COLUMN agency_fee DECIMAL(12,2);
        COMMENT ON COLUMN event_comments.agency_fee IS 'Compensi da consegnare all''agenzia';
    END IF;

    -- Flag consegna avvenuta
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'event_comments' AND column_name = 'agency_fee_delivered'
    ) THEN
        ALTER TABLE event_comments ADD COLUMN agency_fee_delivered BOOLEAN DEFAULT FALSE;
        COMMENT ON COLUMN event_comments.agency_fee_delivered IS 'True se i compensi sono stati consegnati';
    END IF;

    -- Data consegna
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'event_comments' AND column_name = 'agency_fee_delivered_at'
    ) THEN
        ALTER TABLE event_comments ADD COLUMN agency_fee_delivered_at TIMESTAMPTZ;
        COMMENT ON COLUMN event_comments.agency_fee_delivered_at IS 'Data/ora consegna compensi';
    END IF;

    -- Flag conferma proprietario
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'event_comments' AND column_name = 'agency_fee_confirmed'
    ) THEN
        ALTER TABLE event_comments ADD COLUMN agency_fee_confirmed BOOLEAN DEFAULT FALSE;
        COMMENT ON COLUMN event_comments.agency_fee_confirmed IS 'True se il proprietario ha confermato ricezione';
    END IF;

    -- Data conferma
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'event_comments' AND column_name = 'agency_fee_confirmed_at'
    ) THEN
        ALTER TABLE event_comments ADD COLUMN agency_fee_confirmed_at TIMESTAMPTZ;
        COMMENT ON COLUMN event_comments.agency_fee_confirmed_at IS 'Data/ora conferma ricezione';
    END IF;

    -- Chi ha confermato
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'event_comments' AND column_name = 'agency_fee_confirmed_by'
    ) THEN
        ALTER TABLE event_comments ADD COLUMN agency_fee_confirmed_by TEXT;
        COMMENT ON COLUMN event_comments.agency_fee_confirmed_by IS 'Email di chi ha confermato la ricezione';
    END IF;

    -- Stato consegna per commenti tipo delivery
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'event_comments' AND column_name = 'delivery_status'
    ) THEN
        ALTER TABLE event_comments ADD COLUMN delivery_status TEXT;
        COMMENT ON COLUMN event_comments.delivery_status IS 'Stato consegna: pending, confirmed, rejected';
    END IF;
END $$;

-- Indice per query compensi non consegnati
CREATE INDEX IF NOT EXISTS idx_event_comments_pending_delivery
ON event_comments(agency_fee_delivered)
WHERE agency_fee > 0 AND agency_fee_delivered = FALSE;

-- Indice per query consegne in attesa conferma
CREATE INDEX IF NOT EXISTS idx_event_comments_pending_confirm
ON event_comments(agency_fee_confirmed)
WHERE agency_fee_delivered = TRUE AND agency_fee_confirmed = FALSE;

-- Aggiorna comment type per includere 'delivery'
COMMENT ON COLUMN event_comments.comment_type IS 'Tipo: normal, income, expense, delivery';
