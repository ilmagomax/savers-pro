-- ============================================
-- FIX RLS POLICIES PER AGENCY_MEMBERS
-- Il problema è la ricorsione infinita nelle policy
-- ============================================

-- Rimuovi le policy problematiche
DROP POLICY IF EXISTS "Users can view own membership" ON agency_members;
DROP POLICY IF EXISTS "Agency admins can view all members" ON agency_members;
DROP POLICY IF EXISTS "Agency admins can invite members" ON agency_members;
DROP POLICY IF EXISTS "Agency admins can update members" ON agency_members;
DROP POLICY IF EXISTS "Agency owner can delete members" ON agency_members;

-- Ricrea policy semplici senza ricorsione

-- 1. SELECT: Utenti possono vedere i membri della propria organizzazione
CREATE POLICY "View agency members"
ON agency_members FOR SELECT
USING (
    -- L'utente può vedere se è membro della stessa agenzia
    agency_id IN (
        SELECT organization_id FROM profiles WHERE id = auth.uid()
    )
    OR
    -- O se è l'owner dell'organizzazione
    agency_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
);

-- 2. INSERT: Solo owner/admin dell'organizzazione possono inserire
CREATE POLICY "Insert agency members"
ON agency_members FOR INSERT
WITH CHECK (
    -- L'utente è owner dell'organizzazione
    agency_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
    OR
    -- O ha ruolo owner/admin nel profilo
    agency_id IN (
        SELECT organization_id FROM profiles
        WHERE id = auth.uid()
        AND org_role IN ('owner', 'admin')
    )
);

-- 3. UPDATE: Owner/admin possono aggiornare
CREATE POLICY "Update agency members"
ON agency_members FOR UPDATE
USING (
    agency_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
    OR
    agency_id IN (
        SELECT organization_id FROM profiles
        WHERE id = auth.uid()
        AND org_role IN ('owner', 'admin')
    )
);

-- 4. DELETE: Solo owner può eliminare
CREATE POLICY "Delete agency members"
ON agency_members FOR DELETE
USING (
    agency_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
);

-- ============================================
-- FIX POLICY PER AGENCY_CALENDAR_ACCESS
-- ============================================

DROP POLICY IF EXISTS "Users can view own calendar access" ON agency_calendar_access;
DROP POLICY IF EXISTS "Agency admins can manage calendar access" ON agency_calendar_access;

CREATE POLICY "View calendar access"
ON agency_calendar_access FOR SELECT
USING (
    agency_id IN (
        SELECT organization_id FROM profiles WHERE id = auth.uid()
    )
    OR
    agency_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
);

CREATE POLICY "Manage calendar access"
ON agency_calendar_access FOR ALL
USING (
    agency_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
    OR
    agency_id IN (
        SELECT organization_id FROM profiles
        WHERE id = auth.uid()
        AND org_role IN ('owner', 'admin')
    )
);

-- ============================================
-- FIX POLICY PER AGENCY_INVITES_LOG
-- ============================================

DROP POLICY IF EXISTS "Agency admins can view invites log" ON agency_invites_log;

CREATE POLICY "View invites log"
ON agency_invites_log FOR SELECT
USING (
    agency_id IN (
        SELECT organization_id FROM profiles WHERE id = auth.uid()
    )
    OR
    agency_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
);

CREATE POLICY "Insert invites log"
ON agency_invites_log FOR INSERT
WITH CHECK (
    agency_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
    OR
    agency_id IN (
        SELECT organization_id FROM profiles
        WHERE id = auth.uid()
        AND org_role IN ('owner', 'admin')
    )
);

-- ============================================
-- VERIFICA
-- ============================================
-- Dopo aver eseguito questo SQL, le query dovrebbero funzionare
