-- ============================================
-- SAVERS PRO - SISTEMA AGENZIE
-- Gestione team, permessi e abbonamenti per agenzie di animazione
-- Esegui DOPO 01-base-schema.sql
-- ============================================

-- ============================================
-- 1. TABELLA AGENCY_MEMBERS
-- Gestisce i membri di un'agenzia con permessi granulari
-- ============================================
CREATE TABLE IF NOT EXISTS agency_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Riferimenti
    agency_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,

    -- Info invito (per utenti non ancora registrati)
    invited_email TEXT,
    invite_token UUID DEFAULT uuid_generate_v4(),
    invite_expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),

    -- Ruolo nell'agenzia
    role TEXT NOT NULL DEFAULT 'animator' CHECK (role IN ('owner', 'admin', 'animator', 'viewer')),

    -- Permessi granulari
    permissions JSONB DEFAULT '{
        "can_see_all_finances": false,
        "can_see_team_finances": false,
        "can_edit_events": true,
        "can_add_financial_comments": true,
        "can_manage_team": false,
        "can_manage_calendars": false,
        "can_export_reports": false,
        "can_access_crm": false
    }',

    -- Calendari assegnati (array di calendar_id Google)
    assigned_calendars JSONB DEFAULT '[]',

    -- Stato
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'suspended', 'revoked')),

    -- Date
    invited_at TIMESTAMPTZ DEFAULT NOW(),
    joined_at TIMESTAMPTZ,
    suspended_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,

    -- Motivo sospensione/revoca
    status_reason TEXT,

    -- Chi ha invitato
    invited_by UUID REFERENCES profiles(id),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraint: email o user_id deve essere presente
    CONSTRAINT email_or_user CHECK (user_id IS NOT NULL OR invited_email IS NOT NULL),

    -- Constraint: utente univoco per agenzia
    CONSTRAINT unique_user_per_agency UNIQUE (agency_id, user_id),
    CONSTRAINT unique_email_per_agency UNIQUE (agency_id, invited_email)
);

-- ============================================
-- 2. TABELLA AGENCY_CALENDAR_ACCESS
-- Mappatura dettagliata accesso calendari
-- ============================================
CREATE TABLE IF NOT EXISTS agency_calendar_access (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    agency_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES agency_members(id) ON DELETE CASCADE,

    -- Info calendario Google
    calendar_id TEXT NOT NULL,
    calendar_name TEXT,
    calendar_color TEXT,

    -- Permessi sul calendario
    can_view BOOLEAN DEFAULT TRUE,
    can_comment BOOLEAN DEFAULT TRUE,
    can_add_finances BOOLEAN DEFAULT TRUE,
    can_edit_events BOOLEAN DEFAULT FALSE,

    -- Date
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    granted_by UUID REFERENCES profiles(id),

    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_calendar_per_member UNIQUE (member_id, calendar_id)
);

-- ============================================
-- 3. TABELLA AGENCY_INVITES_LOG
-- Log di tutti gli inviti (per audit)
-- ============================================
CREATE TABLE IF NOT EXISTS agency_invites_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    agency_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    member_id UUID REFERENCES agency_members(id) ON DELETE SET NULL,

    -- Info invito
    invited_email TEXT NOT NULL,
    invited_by UUID REFERENCES profiles(id),

    -- Azione
    action TEXT NOT NULL CHECK (action IN ('invited', 'accepted', 'declined', 'expired', 'revoked', 'suspended', 'reactivated')),

    -- Dettagli
    details JSONB DEFAULT '{}',

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. FUNZIONE: Verifica se utente è membro attivo di un'agenzia
-- ============================================
CREATE OR REPLACE FUNCTION is_agency_member(p_user_id UUID, p_agency_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM agency_members
        WHERE user_id = p_user_id
        AND agency_id = p_agency_id
        AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 5. FUNZIONE: Ottieni ruolo utente in un'agenzia
-- ============================================
CREATE OR REPLACE FUNCTION get_agency_role(p_user_id UUID, p_agency_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_role TEXT;
BEGIN
    SELECT role INTO v_role
    FROM agency_members
    WHERE user_id = p_user_id
    AND agency_id = p_agency_id
    AND status = 'active';

    RETURN COALESCE(v_role, 'none');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 6. FUNZIONE: Ottieni permessi utente in un'agenzia
-- ============================================
CREATE OR REPLACE FUNCTION get_agency_permissions(p_user_id UUID, p_agency_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_permissions JSONB;
    v_role TEXT;
BEGIN
    SELECT permissions, role INTO v_permissions, v_role
    FROM agency_members
    WHERE user_id = p_user_id
    AND agency_id = p_agency_id
    AND status = 'active';

    -- Se owner o admin, tutti i permessi
    IF v_role IN ('owner', 'admin') THEN
        RETURN '{
            "can_see_all_finances": true,
            "can_see_team_finances": true,
            "can_edit_events": true,
            "can_add_financial_comments": true,
            "can_manage_team": true,
            "can_manage_calendars": true,
            "can_export_reports": true,
            "can_access_crm": true
        }'::JSONB;
    END IF;

    RETURN COALESCE(v_permissions, '{}'::JSONB);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 7. FUNZIONE: Ottieni calendari assegnati a un membro
-- ============================================
CREATE OR REPLACE FUNCTION get_member_calendars(p_user_id UUID, p_agency_id UUID)
RETURNS JSONB AS $$
BEGIN
    RETURN COALESCE(
        (SELECT jsonb_agg(jsonb_build_object(
            'calendar_id', aca.calendar_id,
            'calendar_name', aca.calendar_name,
            'can_view', aca.can_view,
            'can_comment', aca.can_comment,
            'can_add_finances', aca.can_add_finances,
            'can_edit_events', aca.can_edit_events
        ))
        FROM agency_calendar_access aca
        JOIN agency_members am ON am.id = aca.member_id
        WHERE am.user_id = p_user_id
        AND am.agency_id = p_agency_id
        AND am.status = 'active'),
        '[]'::JSONB
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 8. FUNZIONE: Accetta invito
-- ============================================
CREATE OR REPLACE FUNCTION accept_agency_invite(p_invite_token UUID, p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_member agency_members%ROWTYPE;
    v_user_email TEXT;
    v_agency_name TEXT;
BEGIN
    -- Ottieni email utente
    SELECT email INTO v_user_email FROM profiles WHERE id = p_user_id;

    -- Cerca invito valido (case-insensitive email)
    SELECT * INTO v_member
    FROM agency_members
    WHERE invite_token = p_invite_token
    AND status = 'pending'
    AND invite_expires_at > NOW()
    AND (LOWER(invited_email) = LOWER(v_user_email) OR invited_email IS NULL);

    IF v_member.id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invito non trovato o scaduto');
    END IF;

    -- Ottieni nome agenzia
    SELECT name INTO v_agency_name FROM organizations WHERE id = v_member.agency_id;

    -- Aggiorna membro
    UPDATE agency_members
    SET user_id = p_user_id,
        status = 'active',
        joined_at = NOW(),
        invite_token = NULL,
        updated_at = NOW()
    WHERE id = v_member.id;

    -- Aggiorna profilo utente con organization_id e ruolo
    -- Mappa ruoli agency_members -> profiles (animator/viewer -> member, admin -> admin)
    UPDATE profiles
    SET organization_id = v_member.agency_id,
        org_role = CASE
            WHEN v_member.role = 'admin' THEN 'admin'
            WHEN v_member.role = 'owner' THEN 'owner'
            ELSE 'member'  -- animator, viewer -> member
        END,
        updated_at = NOW()
    WHERE id = p_user_id;

    -- Log
    INSERT INTO agency_invites_log (agency_id, member_id, invited_email, action, details)
    VALUES (v_member.agency_id, v_member.id, v_user_email, 'accepted',
            jsonb_build_object('accepted_at', NOW()));

    RETURN jsonb_build_object(
        'success', true,
        'agency_id', v_member.agency_id,
        'agency_name', v_agency_name,
        'role', v_member.role
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 9. ROW LEVEL SECURITY
-- ============================================
ALTER TABLE agency_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE agency_calendar_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE agency_invites_log ENABLE ROW LEVEL SECURITY;

-- Policy: Membri possono vedere la propria membership
CREATE POLICY "Users can view own membership"
ON agency_members FOR SELECT
USING (user_id = auth.uid());

-- Policy: Owner/Admin possono vedere tutti i membri della propria agenzia
CREATE POLICY "Agency admins can view all members"
ON agency_members FOR SELECT
USING (
    agency_id IN (
        SELECT agency_id FROM agency_members
        WHERE user_id = auth.uid()
        AND role IN ('owner', 'admin')
        AND status = 'active'
    )
);

-- Policy: Owner/Admin possono inserire nuovi membri
CREATE POLICY "Agency admins can invite members"
ON agency_members FOR INSERT
WITH CHECK (
    agency_id IN (
        SELECT agency_id FROM agency_members
        WHERE user_id = auth.uid()
        AND role IN ('owner', 'admin')
        AND status = 'active'
    )
    OR
    -- Oppure l'owner dell'organizzazione può invitare
    agency_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
);

-- Policy: Owner/Admin possono aggiornare membri
CREATE POLICY "Agency admins can update members"
ON agency_members FOR UPDATE
USING (
    agency_id IN (
        SELECT agency_id FROM agency_members
        WHERE user_id = auth.uid()
        AND role IN ('owner', 'admin')
        AND status = 'active'
    )
);

-- Policy: Solo owner può eliminare membri
CREATE POLICY "Agency owner can delete members"
ON agency_members FOR DELETE
USING (
    agency_id IN (
        SELECT agency_id FROM agency_members
        WHERE user_id = auth.uid()
        AND role = 'owner'
        AND status = 'active'
    )
);

-- Policy per calendar_access
CREATE POLICY "Users can view own calendar access"
ON agency_calendar_access FOR SELECT
USING (
    member_id IN (SELECT id FROM agency_members WHERE user_id = auth.uid())
);

CREATE POLICY "Agency admins can manage calendar access"
ON agency_calendar_access FOR ALL
USING (
    agency_id IN (
        SELECT agency_id FROM agency_members
        WHERE user_id = auth.uid()
        AND role IN ('owner', 'admin')
        AND status = 'active'
    )
);

-- Policy per invites_log
CREATE POLICY "Agency admins can view invites log"
ON agency_invites_log FOR SELECT
USING (
    agency_id IN (
        SELECT agency_id FROM agency_members
        WHERE user_id = auth.uid()
        AND role IN ('owner', 'admin')
        AND status = 'active'
    )
);

-- ============================================
-- 10. INDICI
-- ============================================
CREATE INDEX IF NOT EXISTS idx_agency_members_agency ON agency_members(agency_id);
CREATE INDEX IF NOT EXISTS idx_agency_members_user ON agency_members(user_id);
CREATE INDEX IF NOT EXISTS idx_agency_members_status ON agency_members(status);
CREATE INDEX IF NOT EXISTS idx_agency_members_email ON agency_members(invited_email);
CREATE INDEX IF NOT EXISTS idx_agency_members_token ON agency_members(invite_token);
CREATE INDEX IF NOT EXISTS idx_agency_calendar_member ON agency_calendar_access(member_id);
CREATE INDEX IF NOT EXISTS idx_agency_calendar_calendar ON agency_calendar_access(calendar_id);

-- ============================================
-- 11. TRIGGER: Aggiorna updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_agency_members_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_agency_members_updated_at ON agency_members;
CREATE TRIGGER update_agency_members_updated_at
    BEFORE UPDATE ON agency_members
    FOR EACH ROW
    EXECUTE FUNCTION update_agency_members_updated_at();

-- ============================================
-- 12. TRIGGER: Auto-crea membership per owner organizzazione
-- ============================================
CREATE OR REPLACE FUNCTION auto_create_owner_membership()
RETURNS TRIGGER AS $$
BEGIN
    -- Quando viene creata un'organizzazione, crea automaticamente la membership per l'owner
    IF NEW.owner_id IS NOT NULL THEN
        INSERT INTO agency_members (agency_id, user_id, role, status, joined_at, permissions)
        VALUES (
            NEW.id,
            NEW.owner_id,
            'owner',
            'active',
            NOW(),
            '{
                "can_see_all_finances": true,
                "can_see_team_finances": true,
                "can_edit_events": true,
                "can_add_financial_comments": true,
                "can_manage_team": true,
                "can_manage_calendars": true,
                "can_export_reports": true,
                "can_access_crm": true
            }'::JSONB
        )
        ON CONFLICT (agency_id, user_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS auto_create_owner_membership ON organizations;
CREATE TRIGGER auto_create_owner_membership
    AFTER INSERT ON organizations
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_owner_membership();

-- ============================================
-- 13. INSERIMENTO MEMBERSHIP PER ORGANIZZAZIONI ESISTENTI
-- ============================================
INSERT INTO agency_members (agency_id, user_id, role, status, joined_at, permissions)
SELECT
    o.id,
    o.owner_id,
    'owner',
    'active',
    COALESCE(o.created_at, NOW()),
    '{
        "can_see_all_finances": true,
        "can_see_team_finances": true,
        "can_edit_events": true,
        "can_add_financial_comments": true,
        "can_manage_team": true,
        "can_manage_calendars": true,
        "can_export_reports": true,
        "can_access_crm": true
    }'::JSONB
FROM organizations o
WHERE o.owner_id IS NOT NULL
ON CONFLICT (agency_id, user_id) DO NOTHING;

-- ============================================
-- FINE SCHEMA SISTEMA AGENZIE
-- ============================================
