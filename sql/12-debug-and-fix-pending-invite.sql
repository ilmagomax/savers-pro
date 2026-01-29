-- ============================================
-- DEBUG E FIX INVITI PENDENTI
-- Esegui questo per vedere lo stato degli inviti e correggerli
-- ============================================

-- 1. Visualizza tutti gli inviti e il loro stato
SELECT
    am.id,
    am.invited_email,
    am.status,
    am.user_id,
    am.joined_at,
    am.invite_expires_at,
    o.name as agency_name,
    p.email as user_email,
    p.displayname
FROM agency_members am
LEFT JOIN organizations o ON am.agency_id = o.id
LEFT JOIN profiles p ON am.user_id = p.id
ORDER BY am.created_at DESC;

-- 2. Se vuoi aggiornare manualmente un invito a "active"
-- SOSTITUISCI 'email@esempio.com' con l'email dell'animatore
/*
UPDATE agency_members
SET status = 'active',
    joined_at = NOW(),
    invite_token = NULL,
    updated_at = NOW()
WHERE invited_email = 'email@esempio.com'
AND status = 'pending';
*/

-- 3. Aggiorna anche il profilo dell'utente (se necessario)
-- SOSTITUISCI i valori con quelli corretti
/*
UPDATE profiles
SET organization_id = (SELECT agency_id FROM agency_members WHERE invited_email = 'email@esempio.com' LIMIT 1),
    org_role = 'animator',
    updated_at = NOW()
WHERE email = 'email@esempio.com';
*/

-- 4. Verifica che la funzione accept_agency_invite esista e sia aggiornata
SELECT
    proname as function_name,
    prosrc as function_body
FROM pg_proc
WHERE proname = 'accept_agency_invite';
