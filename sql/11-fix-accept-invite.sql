-- ============================================
-- FIX FUNZIONE accept_agency_invite
-- Aggiunge: nome agenzia nel risultato + aggiornamento profilo utente
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
