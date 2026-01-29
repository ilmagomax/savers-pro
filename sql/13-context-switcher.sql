-- ============================================
-- CONTEXT SWITCHER - Permette all'utente di switchare tra workspace
-- ============================================

-- 1. Aggiungi campo per il contesto corrente
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS current_context_org_id UUID REFERENCES organizations(id);

-- 2. Crea tabella per memorizzare le organizzazioni accessibili all'utente
-- (oltre alla propria, include quelle dove è membro)
CREATE OR REPLACE VIEW user_accessible_organizations AS
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
        WHEN o.id = p.organization_id THEN true  -- Workspace personale
        ELSE false
    END as is_personal_workspace,
    am.joined_at
FROM profiles p
-- Workspace personale (quello dove l'utente è owner)
LEFT JOIN organizations o ON o.owner_id = p.id
-- Agenzie dove l'utente è membro
LEFT JOIN agency_members am ON am.user_id = p.id AND am.status = 'active'
LEFT JOIN organizations ao ON ao.id = am.agency_id
WHERE o.id IS NOT NULL OR ao.id IS NOT NULL;

-- 3. Funzione per ottenere le organizzazioni accessibili
CREATE OR REPLACE FUNCTION get_user_organizations(p_user_id UUID)
RETURNS TABLE (
    org_id UUID,
    org_name TEXT,
    user_role TEXT,
    is_personal_workspace BOOLEAN,
    is_current BOOLEAN
) AS $$
DECLARE
    v_current_context UUID;
BEGIN
    -- Ottieni il contesto corrente
    SELECT COALESCE(current_context_org_id, organization_id) INTO v_current_context
    FROM profiles WHERE id = p_user_id;

    RETURN QUERY
    SELECT DISTINCT
        o.id as org_id,
        o.name as org_name,
        CASE
            WHEN o.owner_id = p_user_id THEN 'owner'
            WHEN am.role = 'admin' THEN 'admin'
            WHEN am.role = 'animator' THEN 'animator'
            WHEN am.role = 'viewer' THEN 'viewer'
            ELSE 'member'
        END as user_role,
        (o.owner_id = p_user_id) as is_personal_workspace,
        (o.id = v_current_context) as is_current
    FROM organizations o
    LEFT JOIN agency_members am ON am.agency_id = o.id AND am.user_id = p_user_id AND am.status = 'active'
    WHERE o.owner_id = p_user_id  -- Workspace personale
       OR (am.id IS NOT NULL AND am.status = 'active');  -- Agenzie dove è membro
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Funzione per cambiare contesto
CREATE OR REPLACE FUNCTION switch_organization_context(p_user_id UUID, p_org_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_has_access BOOLEAN;
    v_org_name TEXT;
BEGIN
    -- Verifica che l'utente abbia accesso a questa organizzazione
    SELECT EXISTS(
        SELECT 1 FROM organizations o
        LEFT JOIN agency_members am ON am.agency_id = o.id AND am.user_id = p_user_id AND am.status = 'active'
        WHERE o.id = p_org_id
        AND (o.owner_id = p_user_id OR am.id IS NOT NULL)
    ) INTO v_has_access;

    IF NOT v_has_access THEN
        RETURN jsonb_build_object('success', false, 'error', 'Accesso non autorizzato a questa organizzazione');
    END IF;

    -- Ottieni nome organizzazione
    SELECT name INTO v_org_name FROM organizations WHERE id = p_org_id;

    -- Aggiorna il contesto
    UPDATE profiles
    SET current_context_org_id = p_org_id,
        updated_at = NOW()
    WHERE id = p_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'org_id', p_org_id,
        'org_name', v_org_name
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Aggiungi indice per performance
CREATE INDEX IF NOT EXISTS idx_profiles_current_context ON profiles(current_context_org_id);

-- 6. Commento
COMMENT ON COLUMN profiles.current_context_org_id IS 'ID dell''organizzazione attualmente selezionata dall''utente (workspace personale o agenzia)';
