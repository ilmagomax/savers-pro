-- ============================================
-- SISTEMA ANNUNCI BACHECA AGENZIA
-- Owner/Admin possono creare annunci visibili agli animatori
-- ============================================

-- 1. Tabella annunci
CREATE TABLE IF NOT EXISTS agency_announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES profiles(id),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    is_pinned BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ,  -- Se null, non scade
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabella per tracciare chi ha letto l'annuncio
CREATE TABLE IF NOT EXISTS agency_announcement_reads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    announcement_id UUID NOT NULL REFERENCES agency_announcements(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(announcement_id, user_id)
);

-- 3. Indici per performance
CREATE INDEX IF NOT EXISTS idx_announcements_agency ON agency_announcements(agency_id);
CREATE INDEX IF NOT EXISTS idx_announcements_created ON agency_announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcement_reads_user ON agency_announcement_reads(user_id);

-- 4. RLS Policies
ALTER TABLE agency_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE agency_announcement_reads ENABLE ROW LEVEL SECURITY;

-- Annunci: tutti i membri dell'agenzia possono leggere
CREATE POLICY "View agency announcements"
ON agency_announcements FOR SELECT
USING (
    agency_id IN (
        SELECT organization_id FROM profiles WHERE id = auth.uid()
    )
    OR
    agency_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
    OR
    agency_id IN (
        SELECT agency_id FROM agency_members WHERE user_id = auth.uid() AND status = 'active'
    )
);

-- Annunci: solo owner/admin possono creare
CREATE POLICY "Create agency announcements"
ON agency_announcements FOR INSERT
WITH CHECK (
    agency_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
    OR
    agency_id IN (
        SELECT organization_id FROM profiles
        WHERE id = auth.uid() AND org_role IN ('owner', 'admin')
    )
);

-- Annunci: solo owner/admin possono modificare
CREATE POLICY "Update agency announcements"
ON agency_announcements FOR UPDATE
USING (
    agency_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
    OR
    agency_id IN (
        SELECT organization_id FROM profiles
        WHERE id = auth.uid() AND org_role IN ('owner', 'admin')
    )
);

-- Annunci: solo owner/admin possono eliminare
CREATE POLICY "Delete agency announcements"
ON agency_announcements FOR DELETE
USING (
    agency_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
    OR
    agency_id IN (
        SELECT organization_id FROM profiles
        WHERE id = auth.uid() AND org_role IN ('owner', 'admin')
    )
);

-- Letture: utenti gestiscono le proprie
CREATE POLICY "Manage own announcement reads"
ON agency_announcement_reads FOR ALL
USING (user_id = auth.uid());

-- 5. Funzione per ottenere annunci con stato lettura
CREATE OR REPLACE FUNCTION get_agency_announcements(p_agency_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    title TEXT,
    content TEXT,
    priority TEXT,
    is_pinned BOOLEAN,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    created_by_name TEXT,
    created_by_avatar TEXT,
    is_read BOOLEAN,
    read_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.id,
        a.title,
        a.content,
        a.priority,
        a.is_pinned,
        a.expires_at,
        a.created_at,
        COALESCE(p.full_name, p.email) as created_by_name,
        p.avatar_url as created_by_avatar,
        (ar.id IS NOT NULL) as is_read,
        ar.read_at
    FROM agency_announcements a
    LEFT JOIN profiles p ON p.id = a.created_by
    LEFT JOIN agency_announcement_reads ar ON ar.announcement_id = a.id AND ar.user_id = p_user_id
    WHERE a.agency_id = p_agency_id
    AND (a.expires_at IS NULL OR a.expires_at > NOW())
    ORDER BY a.is_pinned DESC, a.priority = 'urgent' DESC, a.priority = 'high' DESC, a.created_at DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Funzione per segnare annuncio come letto
CREATE OR REPLACE FUNCTION mark_announcement_read(p_announcement_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO agency_announcement_reads (announcement_id, user_id)
    VALUES (p_announcement_id, p_user_id)
    ON CONFLICT (announcement_id, user_id) DO NOTHING;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Trigger per updated_at
CREATE OR REPLACE FUNCTION update_announcement_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_announcement_timestamp ON agency_announcements;
CREATE TRIGGER trigger_update_announcement_timestamp
    BEFORE UPDATE ON agency_announcements
    FOR EACH ROW
    EXECUTE FUNCTION update_announcement_timestamp();
