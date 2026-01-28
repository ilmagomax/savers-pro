-- ============================================
-- MIGRATION: Tabella event_comments per Supabase
-- Data: 2026-01-28
-- ============================================

-- Tabella per commenti evento (inclusi commenti finanziari)
CREATE TABLE IF NOT EXISTS event_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    event_id TEXT NOT NULL,  -- ID evento Google Calendar o locale
    event_comment_id TEXT,   -- ID universale per commenti condivisi (iCalUID)

    text TEXT,
    comment_type TEXT DEFAULT 'normal', -- 'normal', 'income', 'expense'
    amount DECIMAL(12,2),  -- NULL per commenti normali, numero per finanziari

    author_id TEXT,
    author_name TEXT,
    author_email TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indici per query veloci
CREATE INDEX IF NOT EXISTS idx_event_comments_user ON event_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_event_comments_event ON event_comments(event_id);
CREATE INDEX IF NOT EXISTS idx_event_comments_comment_id ON event_comments(event_comment_id);
CREATE INDEX IF NOT EXISTS idx_event_comments_type ON event_comments(comment_type) WHERE comment_type != 'normal';

-- RLS Policies
ALTER TABLE event_comments ENABLE ROW LEVEL SECURITY;

-- Tutti possono vedere i commenti degli eventi a cui partecipano
-- (la logica di visibilità per commenti finanziari è gestita nel frontend)
CREATE POLICY "Users can view event comments"
ON event_comments FOR SELECT
TO authenticated
USING (true);  -- Visibilità gestita nel frontend con canSeeFinancialComment()

-- Gli utenti possono inserire commenti
CREATE POLICY "Users can insert event comments"
ON event_comments FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Gli utenti possono modificare i propri commenti
CREATE POLICY "Users can update own event comments"
ON event_comments FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

-- Gli utenti possono eliminare i propri commenti
CREATE POLICY "Users can delete own event comments"
ON event_comments FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Commenti
COMMENT ON TABLE event_comments IS 'Commenti eventi calendario (inclusi commenti finanziari per animatori)';
COMMENT ON COLUMN event_comments.comment_type IS 'Tipo: normal, income, expense';
COMMENT ON COLUMN event_comments.amount IS 'Importo per commenti finanziari (positivo income, negativo expense)';
COMMENT ON COLUMN event_comments.event_comment_id IS 'ID universale per sincronizzare commenti tra dispositivi (iCalUID)';
