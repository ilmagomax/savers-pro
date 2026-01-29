-- ============================================
-- FIX ERRORI DI SICUREZZA SUPABASE
-- 1. Rimuove SECURITY DEFINER dalla view
-- 2. Abilita RLS sulla tabella achievements
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
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

-- Policy per achievements: ogni utente vede solo i propri
DROP POLICY IF EXISTS "Users can view own achievements" ON achievements;
CREATE POLICY "Users can view own achievements"
ON achievements FOR SELECT
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own achievements" ON achievements;
CREATE POLICY "Users can insert own achievements"
ON achievements FOR INSERT
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own achievements" ON achievements;
CREATE POLICY "Users can update own achievements"
ON achievements FOR UPDATE
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own achievements" ON achievements;
CREATE POLICY "Users can delete own achievements"
ON achievements FOR DELETE
USING (user_id = auth.uid());

-- 3. Verifica: mostra le policy create
-- SELECT * FROM pg_policies WHERE tablename = 'achievements';
