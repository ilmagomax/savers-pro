-- ============================================
-- MIGRATION: Aggiunge tabella wallets (portafogli/conti)
-- Data: 2026-01-28
-- ============================================

-- Tabella per wallet/conti
CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    name TEXT NOT NULL,
    icon TEXT DEFAULT '💳',
    type TEXT NOT NULL DEFAULT 'cash', -- cash, bank, card, crypto, investment
    color TEXT DEFAULT '#6366f1',

    initial_balance DECIMAL(12,2) DEFAULT 0,
    current_balance DECIMAL(12,2) DEFAULT 0,
    currency TEXT DEFAULT 'EUR',

    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    include_in_total BOOLEAN DEFAULT TRUE, -- Include nel calcolo patrimonio totale

    bank_name TEXT, -- Nome banca (opzionale)
    account_number TEXT, -- Ultimi 4 cifre (opzionale)

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indice per query veloci
CREATE INDEX IF NOT EXISTS idx_wallets_user ON wallets(user_id);

-- RLS Policies
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own wallets"
ON wallets FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can insert own wallets"
ON wallets FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own wallets"
ON wallets FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can delete own wallets"
ON wallets FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Aggiungi colonna wallet_id alla tabella transactions (se esiste)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'transactions' AND column_name = 'wallet_id'
    ) THEN
        ALTER TABLE transactions ADD COLUMN wallet_id UUID REFERENCES wallets(id) ON DELETE SET NULL;
        CREATE INDEX IF NOT EXISTS idx_transactions_wallet ON transactions(wallet_id);
    END IF;
END $$;

-- Commenti
COMMENT ON TABLE wallets IS 'Portafogli/conti utente per tracciare patrimonio';
COMMENT ON COLUMN wallets.type IS 'Tipo: cash, bank, card, crypto, investment';
COMMENT ON COLUMN wallets.include_in_total IS 'Se includere nel calcolo del patrimonio totale';
