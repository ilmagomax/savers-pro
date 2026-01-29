# SAVERS PRO - Context File per Claude Code
> Aggiornato: 2026-01-29 (Sessione serale) - Sistema Annunci + Documenti Agenzia

## STATO PROGETTO ATTUALE

### Sessione 2026-01-29 (Serale) - RIEPILOGO

**Completato oggi:**
1. ✅ Modal "Nuovo Annuncio" - risolto problema di visualizzazione (cache browser + stili inline)
2. ✅ Sistema annunci con link allegati (Google Drive)
3. ✅ Modifica/elimina annunci per owner
4. ✅ Design migliorato con intestazioni leggibili
5. ✅ Sezione "Manuali & Policy" per owner e animatori
6. ✅ Fix errori sicurezza Supabase (SQL pronto)

**Bloccato:**
- ⚠️ Deploy Vercel: limite giornaliero raggiunto (100 deploy) - riprova tra ~13 ore
- I commit sono già pushati su GitHub, il deploy avverrà automaticamente

**SQL da eseguire su Supabase:**
- `sql/14-agency-announcements.sql` - ESEGUITO ✅
- `sql/15-fix-security-errors.sql` - ESEGUITO ✅

---

### Sistema Auth Unificato (COMPLETATO 2026-01-29)

Il sistema di autenticazione è stato completamente riscritto per gestire il refresh automatico del token Google attraverso Supabase.

#### Architettura Token Unificata
```javascript
// tokenManager (~riga 7159)
const tokenManager = {
    init()                    // Avvia controllo periodico + event listeners
    getValidToken()           // Restituisce token valido, rinnovandolo se necessario
    checkAndRefresh()         // Verifica scadenza e rinnova preventivamente
    refreshFromSupabase()     // Ottiene nuovo token da Supabase session
    handleAuthError()         // Gestisce errori auth
    showReconnectButton()     // Mostra pulsante riconnessione
};

// Wrapper per chiamate GAPI (~riga 7369)
async function withValidGoogleToken(apiCallFn) {
    // 1. Ottiene token valido da tokenManager
    // 2. Aggiorna GAPI con il token
    // 3. Esegue la chiamata API
    // 4. Se 401, rinnova token e riprova automaticamente
}
```

#### Flusso Token
1. L'utente fa login con Google tramite Supabase
2. Supabase salva `provider_token` nella sessione
3. `tokenManager.init()` avvia controllo ogni 5 minuti
4. Prima di ogni chiamata GAPI, `withValidGoogleToken()` verifica/rinnova il token
5. Se il token è in scadenza (<5 min), viene rinnovato preventivamente
6. Se scaduto, viene fatto refresh tramite `sb.auth.refreshSession()`

### Sistema Compensi Agenzia (IN LAVORAZIONE)

Sistema di gestione compensi per agenzie di animazione con flusso bidirezionale animatore-proprietario.

#### Struttura Dati Commento Finanziario (Income)
```javascript
{
    id: 'comment_xxx',
    type: 'income',
    incomeTotal: 100,           // Ritiro Saldo totale
    animatorProfit: 50,         // Guadagno animatore (Tuo Guadagno)
    animatorExpenses: 20,       // Spese sostenute dall'animatore
    agencyFee: 30,              // Compensi Agenzia (da consegnare)
    agencyFeeDelivered: false,  // Segnato come consegnato
    agencyFeeConfirmed: false,  // Confermato dal proprietario
    agencyFeeModifiedByOwner: false,  // Owner ha modificato l'importo
    agencyFeeAnimatorAccepted: false, // Animatore ha accettato modifica
    agencyFeeLog: []            // Log attività con timestamp
}
```

#### Flusso Consegna Compensi
1. **PENDING**: Animatore registra incasso, compensi da consegnare
2. **PENDING_OWNER_CONFIRMATION**: Animatore clicca "Segna come Consegnato"
3. Owner può:
   - **Confermare** → stato CONFIRMED
   - **Modificare importo** → stato PENDING_ANIMATOR_CONFIRMATION
4. Se modificato, Animatore può:
   - **Accettare** → torna a PENDING_OWNER_CONFIRMATION
   - **Rifiutare** → torna a PENDING (deve ri-consegnare)

### Sistema Agenzia (AGGIORNATO 2026-01-29)

**File SQL**:
- `sql/09-agency-system.sql` - Schema base (ESEGUITO ✅)
- `sql/10-fix-agency-rls.sql` - Fix RLS policies (ESEGUITO ✅)
- `sql/11-fix-accept-invite.sql` - Fix mapping ruoli (ESEGUITO ✅)
- `sql/13-context-switcher.sql` - Context switcher (DA ESEGUIRE)
- `sql/14-agency-announcements.sql` - Annunci + documenti (ESEGUITO ✅)
- `sql/15-fix-security-errors.sql` - Fix sicurezza (ESEGUITO ✅)

**Tabelle Database**:
- `agency_members` - Membri dell'agenzia con ruoli e permessi granulari
- `agency_calendar_access` - Calendari assegnati a ogni membro
- `agency_invites_log` - Log di inviti/revoche per audit
- `agency_announcements` - Annunci bacheca con link_url per allegati
- `agency_announcement_reads` - Traccia lettura annunci
- `agency_documents` - Documenti/policy agenzia (manuali, contratti, formazione)
- `agency_document_reads` - Traccia lettura documenti obbligatori

**Funzioni JS Annunci (NUOVO)**:
- `openCreateAnnouncementModal()` - Apre modal con stili forzati (fix cache)
- `closeAnnouncementModal()` - Chiude e resetta form
- `saveAnnouncement()` - Salva/aggiorna annuncio con link_url
- `editAnnouncement(id)` - Carica annuncio nel form per modifica
- `deleteAnnouncement(id)` - Elimina annuncio
- `loadOwnerAnnouncements()` - Carica lista annunci per owner
- `renderAnnouncementItem()` - Renderizza singolo annuncio con design migliorato

**Funzioni JS Documenti (NUOVO)**:
- `openCreateDocumentModal()` - Apre modal creazione documento
- `closeDocumentModal()` - Chiude modal documento
- `saveDocument()` - Salva/aggiorna documento
- `editDocument(id)` - Modifica documento esistente
- `deleteDocument(id)` - Elimina documento
- `loadOwnerDocuments()` - Carica documenti per owner
- `loadMyAgencyDocuments()` - Carica documenti per animatori
- `renderDocumentItem()` - Renderizza documento con categoria colorata
- `markDocumentAsRead(id)` - Segna documento come letto

**Categorie Documenti**:
- `manual` - 📖 Manuale (sfondo blu)
- `policy` - 📋 Policy/Regolamento (sfondo giallo)
- `contract` - 📝 Contratto (sfondo rosso)
- `training` - 🎓 Formazione (sfondo verde)
- `general` - 📁 Generale (sfondo grigio)

### Bug Risolti (2026-01-29)

1. **Modal annunci non si apriva** - Il problema era duplice:
   - Cache browser con vecchia versione (`class="modal"` invece di `class="modal-overlay"`)
   - Soluzione: stili CSS inline forzati in `openCreateAnnouncementModal()`
2. **Errore SQL `get_agency_announcements`** - Funzione esistente con signature diversa
   - Soluzione: aggiunto `DROP FUNCTION IF EXISTS` prima di CREATE
3. **Errore RLS `achievements`** - Tabella definizioni senza `user_id`
   - Soluzione: policy `USING (true)` per lettura pubblica

---

### Da Completare / Testare

**SQL da eseguire:**
- [ ] `sql/13-context-switcher.sql` - Context switcher workspace

**Funzionalità da testare:**
- [ ] Verificare unificazione commenti su eventi duplicati
- [ ] Testare flusso completo consegna compensi
- [ ] Testare modifica importo da owner e accetta/rifiuta da animatore
- [ ] Testare creazione/modifica annunci con link Drive
- [ ] Testare sezione documenti per owner e animatori

**Da implementare:**
- [ ] Revoca animatore → revoca accesso calendario Google
- [ ] Integrare Stripe per upgrade piani

---

## CONFIGURAZIONE

### Repository
- **GitHub**: https://github.com/ilmagomax/savers-pro
- **Vercel**: https://savers-pro.vercel.app
- **Branch**: main

### Supabase
- **URL**: https://lsrzcsymiuoutcmhcain.supabase.co
- **Anon Key**: sb_publishable_NFzbjbgsGgEn5enQg7M2VQ_XJoFb9RM

---

## FASI COMPLETATE

- [x] FASE 0: Setup Progetto
- [x] FASE 1: Auth Migration a Supabase
- [x] FASE 2: Migrazione Dati Personali (Habits, Tasks, Transactions, Books, Goals, Notes, Money Goals)
- [x] FASE 2+: Wallets, Commenti Finanziari Eventi, OCR Scontrini

## FASI FUTURE

- [ ] FASE 3: Team & Progetti
- [ ] FASE 4: Videocorsi
- [ ] FASE 5: Shop
- [ ] FASE 6: Push Notifications

---

## NOTE PER NUOVA CHAT

```
Leggi /Users/ilmagicartista/Downloads/savers pro per la vendita/CLAUDE_CONTEXT.md

CONTESTO: Continuazione sessione 2026-01-29 serale.

STATO:
- Deploy Vercel bloccato (limite 100/giorno) - dovrebbe essere disponibile ora
- SQL eseguiti: 14 (annunci+documenti), 15 (fix sicurezza)
- SQL da eseguire: 13 (context switcher)

DA TESTARE:
1. Modal "Nuovo Annuncio" funziona dopo deploy?
2. Creazione annunci con link Google Drive
3. Sezione "Manuali & Policy" per owner
4. Visualizzazione documenti per animatori

PROSSIMI PASSI:
1. Verificare deploy Vercel completato
2. Testare sistema annunci completo
3. Testare sistema documenti
4. Eseguire sql/13-context-switcher.sql se necessario

FILE PRINCIPALE: /Users/ilmagicartista/Downloads/savers pro per la vendita/index.html
```
