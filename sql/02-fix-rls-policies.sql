-- ============================================
-- FIX RLS POLICIES per permettere creazione profili
-- Esegui in Supabase Dashboard > SQL Editor
-- ============================================

-- Prima rimuovi le policy esistenti che potrebbero bloccare
DROP POLICY IF EXISTS "Users can view own org" ON organizations;
DROP POLICY IF EXISTS "Owners can update own org" ON organizations;
DROP POLICY IF EXISTS "Anyone can create org" ON organizations;
DROP POLICY IF EXISTS "Users can view profiles in same org" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- ============================================
-- ORGANIZATIONS - Policy corrette
-- ============================================

-- Chiunque autenticato può creare una organizzazione
CREATE POLICY "Authenticated users can create org"
ON organizations FOR INSERT
TO authenticated
WITH CHECK (true);

-- Gli utenti possono vedere la propria organizzazione
CREATE POLICY "Users can view own org"
ON organizations FOR SELECT
TO authenticated
USING (
    id IN (SELECT organization_id FROM profiles WHERE id = auth.uid())
    OR owner_id = auth.uid()
);

-- I proprietari possono aggiornare la propria organizzazione
CREATE POLICY "Owners can update own org"
ON organizations FOR UPDATE
TO authenticated
USING (owner_id = auth.uid());

-- ============================================
-- PROFILES - Policy corrette
-- ============================================

-- Gli utenti possono creare il proprio profilo (id deve corrispondere)
CREATE POLICY "Users can create own profile"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

-- Gli utenti possono vedere profili nella stessa org o il proprio
CREATE POLICY "Users can view profiles"
ON profiles FOR SELECT
TO authenticated
USING (
    id = auth.uid()
    OR organization_id IN (SELECT organization_id FROM profiles WHERE id = auth.uid())
);

-- Gli utenti possono aggiornare solo il proprio profilo
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (id = auth.uid());

-- ============================================
-- VERIFICA
-- ============================================
-- Dopo aver eseguito, verifica con:
-- SELECT * FROM pg_policies WHERE tablename IN ('organizations', 'profiles');
