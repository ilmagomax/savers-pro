-- ============================================
-- FIX ERRORI DI SICUREZZA SUPABASE
-- 1. Rimuove SECURITY DEFINER dalla view
-- 2. Abilita RLS sulla tabella achievements (tabella definizioni, pubblica in lettura)
-- ============================================

-- 1. Fix view user_accessible_organizations - rimuove SECURITY DEFINER
-- Prima elimina la view esistente, poi ricreala senza SECURITY DEFINER
DROP VIEW IF EXISTS user_accessible_organizations;

CREATE VIEW user_accessible_organizations AS
SELECT DISTINCT
    p.id as user_id,
    o.id as org_id,
    o.name as org_name,
    o.owner_id,
    CASE
        WHEN o.owner_id = p.id THEN 'owner'
        WHEN am.role = 'admin' THEN 'admin'
        WHEN am.role = 'animator' THEN 'animator'
        WHEN am.role = 'viewer' THEN 'viewer'
        ELSE 'member'
    END as user_role,
    CASE
        WHEN o.id = p.organization_id THEN true
        ELSE false
    END as is_personal_workspace,
    am.joined_at
FROM profiles p
LEFT JOIN organizations o ON o.owner_id = p.id
LEFT JOIN agency_members am ON am.user_id = p.id AND am.status = 'active'
LEFT JOIN organizations ao ON ao.id = am.agency_id
WHERE o.id IS NOT NULL OR ao.id IS NOT NULL;

-- 2. Abilita RLS sulla tabella achievements
-- NOTA: achievements è una tabella di definizioni (non ha user_id)
-- Tutti possono leggerla, solo admin/sistema può modificarla
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

-- Policy per achievements: tutti possono leggere le definizioni
DROP POLICY IF EXISTS "Anyone can view achievements" ON achievements;
CREATE POLICY "Anyone can view achievements"
ON achievements FOR SELECT
USING (true);

-- Solo service_role può modificare achievements (gestito lato backend)
-- Non servono policy per INSERT/UPDATE/DELETE per utenti normali

-- 3. Verifica: mostra le policy create
-- SELECT * FROM pg_policies WHERE tablename = 'achievements';
