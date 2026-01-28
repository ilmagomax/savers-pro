-- ============================================
-- MIGRATION: Aggiunge tabella money_goals
-- Data: 2026-01-28
-- ============================================

-- Tabella per obiettivi finanziari
CREATE TABLE IF NOT EXISTS money_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    name TEXT NOT NULL,
    icon TEXT DEFAULT '🏦',
    target_amount DECIMAL(12,2) NOT NULL,
    current_amount DECIMAL(12,2) DEFAULT 0,
    deadline DATE,

    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indice per query veloci
CREATE INDEX IF NOT EXISTS idx_money_goals_user ON money_goals(user_id);

-- RLS Policies
ALTER TABLE money_goals ENABLE ROW LEVEL SECURITY;

-- Users can see their own goals
CREATE POLICY "Users can view own money goals"
ON money_goals FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can insert their own goals
CREATE POLICY "Users can insert own money goals"
ON money_goals FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can update their own goals
CREATE POLICY "Users can update own money goals"
ON money_goals FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

-- Users can delete their own goals
CREATE POLICY "Users can delete own money goals"
ON money_goals FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Commenti
COMMENT ON TABLE money_goals IS 'Obiettivi finanziari utente';
COMMENT ON COLUMN money_goals.target_amount IS 'Importo obiettivo';
COMMENT ON COLUMN money_goals.current_amount IS 'Importo attuale risparmiato';
