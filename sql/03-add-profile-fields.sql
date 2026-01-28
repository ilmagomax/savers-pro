-- ============================================
-- MIGRATION: Aggiunge campi profilo mancanti
-- Data: 2026-01-28
-- ============================================

-- Aggiungi campi profession e stage_name alla tabella profiles
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS profession TEXT,
ADD COLUMN IF NOT EXISTS stage_name TEXT;

-- Commento per documentazione
COMMENT ON COLUMN profiles.profession IS 'Professione utente (magician, musician, actor, etc.)';
COMMENT ON COLUMN profiles.stage_name IS 'Nome d''arte / nickname dell''utente';
