-- ============================================
-- SISTEMA ANNUNCI BACHECA AGENZIA
-- Owner/Admin possono creare annunci visibili agli animatori
-- ============================================

-- 0. Drop funzioni esistenti per evitare conflitti
DROP FUNCTION IF EXISTS get_agency_announcements(uuid, uuid);
DROP FUNCTION IF EXISTS mark_announcement_read(uuid, uuid);
DROP FUNCTION IF EXISTS get_agency_documents(uuid, uuid);
DROP FUNCTION IF EXISTS mark_document_read(uuid, uuid);

-- 1. Tabella annunci
CREATE TABLE IF NOT EXISTS agency_announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES profiles(id),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    link_url TEXT,  -- Link opzionale (Google Drive, sito, ecc.)
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    is_pinned BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ,  -- Se null, non scade
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Se la tabella esiste già, aggiungi la colonna link_url
ALTER TABLE agency_announcements ADD COLUMN IF NOT EXISTS link_url TEXT;

-- 2. Tabella per tracciare chi ha letto l'annuncio
CREATE TABLE IF NOT EXISTS agency_announcement_reads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    announcement_id UUID NOT NULL REFERENCES agency_announcements(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(announcement_id, user_id)
);

-- 3. Tabella documenti/policy agenzia
CREATE TABLE IF NOT EXISTS agency_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES profiles(id),
    title TEXT NOT NULL,
    description TEXT,
    document_url TEXT NOT NULL,  -- Link Google Drive o altro
    category TEXT DEFAULT 'general' CHECK (category IN ('manual', 'policy', 'contract', 'training', 'general')),
    is_required BOOLEAN DEFAULT FALSE,  -- Documento obbligatorio da leggere
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Tabella per tracciare chi ha letto i documenti obbligatori
CREATE TABLE IF NOT EXISTS agency_document_reads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES agency_documents(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(document_id, user_id)
);

-- 5. Indici per performance
CREATE INDEX IF NOT EXISTS idx_announcements_agency ON agency_announcements(agency_id);
CREATE INDEX IF NOT EXISTS idx_announcements_created ON agency_announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcement_reads_user ON agency_announcement_reads(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_agency ON agency_documents(agency_id);
CREATE INDEX IF NOT EXISTS idx_documents_category ON agency_documents(category);
CREATE INDEX IF NOT EXISTS idx_document_reads_user ON agency_document_reads(user_id);

-- 6. RLS Policies per annunci
ALTER TABLE agency_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE agency_announcement_reads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "View agency announcements" ON agency_announcements;
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

DROP POLICY IF EXISTS "Create agency announcements" ON agency_announcements;
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

DROP POLICY IF EXISTS "Update agency announcements" ON agency_announcements;
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

DROP POLICY IF EXISTS "Delete agency announcements" ON agency_announcements;
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

DROP POLICY IF EXISTS "Manage own announcement reads" ON agency_announcement_reads;
CREATE POLICY "Manage own announcement reads"
ON agency_announcement_reads FOR ALL
USING (user_id = auth.uid());

-- 7. RLS Policies per documenti
ALTER TABLE agency_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE agency_document_reads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "View agency documents" ON agency_documents;
CREATE POLICY "View agency documents"
ON agency_documents FOR SELECT
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

DROP POLICY IF EXISTS "Manage agency documents" ON agency_documents;
CREATE POLICY "Manage agency documents"
ON agency_documents FOR ALL
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

DROP POLICY IF EXISTS "Manage own document reads" ON agency_document_reads;
CREATE POLICY "Manage own document reads"
ON agency_document_reads FOR ALL
USING (user_id = auth.uid());

-- 8. Funzione per ottenere annunci con stato lettura
CREATE OR REPLACE FUNCTION get_agency_announcements(p_agency_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    title TEXT,
    content TEXT,
    link_url TEXT,
    priority TEXT,
    is_pinned BOOLEAN,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
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
        a.link_url,
        a.priority,
        a.is_pinned,
        a.expires_at,
        a.created_at,
        a.updated_at,
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
    LIMIT 50;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Funzione per ottenere documenti agenzia
CREATE OR REPLACE FUNCTION get_agency_documents(p_agency_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    document_url TEXT,
    category TEXT,
    is_required BOOLEAN,
    sort_order INTEGER,
    created_at TIMESTAMPTZ,
    is_read BOOLEAN,
    read_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.id,
        d.title,
        d.description,
        d.document_url,
        d.category,
        d.is_required,
        d.sort_order,
        d.created_at,
        (dr.id IS NOT NULL) as is_read,
        dr.read_at
    FROM agency_documents d
    LEFT JOIN agency_document_reads dr ON dr.document_id = d.id AND dr.user_id = p_user_id
    WHERE d.agency_id = p_agency_id
    ORDER BY d.is_required DESC, d.sort_order ASC, d.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Funzione per segnare annuncio come letto
CREATE OR REPLACE FUNCTION mark_announcement_read(p_announcement_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO agency_announcement_reads (announcement_id, user_id)
    VALUES (p_announcement_id, p_user_id)
    ON CONFLICT (announcement_id, user_id) DO NOTHING;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Funzione per segnare documento come letto
CREATE OR REPLACE FUNCTION mark_document_read(p_document_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO agency_document_reads (document_id, user_id)
    VALUES (p_document_id, p_user_id)
    ON CONFLICT (document_id, user_id) DO NOTHING;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Trigger per updated_at
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

DROP TRIGGER IF EXISTS trigger_update_document_timestamp ON agency_documents;
CREATE TRIGGER trigger_update_document_timestamp
    BEFORE UPDATE ON agency_documents
    FOR EACH ROW
    EXECUTE FUNCTION update_announcement_timestamp();
