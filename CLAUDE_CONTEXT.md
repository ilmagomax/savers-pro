# SAVERS PRO - Context File per Claude Code
> Aggiornato: 2026-01-29 - Autenticazione Unificata Google + Supabase

## STATO PROGETTO ATTUALE

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

#### Tutte le chiamate GAPI ora usano il wrapper:
- `loadUserCalendars()` - Lista calendari
- `loadCalendarEvents()` - Lista eventi
- `createCalendarEvent()` - Crea evento
- `deleteGoogleEvent()` - Elimina evento
- `updateGoogleEvent()` - Aggiorna evento
- `respondToInvite()` - Risponde a invito
- `saveBusyEvent()` - Salva non disponibilità
- `createCalendarEventToCalendar()` - Crea con invitati
- `findFreeSlots()` - Cerca slot liberi
- `scheduleHabitToCalendar()` - Schedula abitudine

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

#### Vista Finanziaria Differenziata

**Vista Agenzia (Owner/Admin):**
- Ritiro Saldo: €100
- Spese Totali: €70 (€50 guadagno anim. + €20 spese)
- Profitto Agenzia: €30

**Vista Animatore (4 colonne):**
- Ritiro Saldo: €100
- Spese: €20
- Guadagno: €50
- Compensi Ag.: €30

#### Identificazione Eventi Duplicati (NUOVO!)

Gli eventi duplicati su calendari diversi vengono unificati tramite hash:
```javascript
// Hash universale = titolo (lowercase) + data/ora (normalizzata)
// SENZA organizer - così eventi duplicati hanno stesso ID
const summary = event.summary.trim().toLowerCase();
const startTime = normalizeDateTime(event.start.dateTime);
const universalId = 'evt_' + simpleHash(`${summary}|${startTime}`);
```

**Funzione chiave**: `getEventCommentId(event, isGoogle)` (~riga 29835)

Quando owner apre un evento, cerca commenti su TUTTI gli ID possibili:
- event.id (specifico calendario)
- iCalUID
- recurringEventId
- Hash universale (titolo + data/ora)

#### Permessi Modifica/Elimina Commenti
- **Owner/Admin**: Può SEMPRE modificare/eliminare qualsiasi commento
- **Animatore**: Può modificare/eliminare SOLO i propri commenti entro 5 minuti

#### Funzioni Chiave (index.html)
- `getEventCommentId(event, isGoogle)` - Genera ID universale (~riga 29835)
- `simpleHash(str)` - Hash deterministico (~riga 29875)
- `renderAgencyFeeWallet()` - Wallet Compensi mensile (~riga 17653)
- `openAgencyFeeDetail()` - Modal dettaglio compensi
- `markAgencyFeesAsDelivered()` - Animatore segna consegnato
- `confirmAgencyFeesReceived()` - Owner conferma ricezione
- `getAgencyFeesForMonth(yearMonth)` - Calcola compensi per mese (~riga 17570)
- `renderEventsDashboard()` - Dashboard Feste & Eventi (~riga 18737)
- `renderEventFinanceSummaryFromComments()` - Riepilogo evento (~riga 17314)
- `showEventFinanceDetail()` - Dettaglio evento dalla dashboard (~riga 19215)
- `canSeeFinancialComment()` - Controllo visibilità commenti (~riga 30880)
- `renderEventComments()` - Renderizza commenti con unificazione (~riga 30137)

### Bug Risolti (2026-01-28/29)

1. **Calcoli finanziari errati** - Usava `animatorEarning` invece di `animatorProfit`
2. **guadagnoAnimatore mancante** - Variabile non dichiarata in showEventFinanceDetail
3. **Fallback calcolo** - Se `animatorProfit` è null, calcola `incomeTotal - agencyFee - animatorExpenses`
4. **Owner vede tutti i commenti** - Aggiunto check `isOwnerOrAdmin` in `canSeeFinancialComment()`
5. **Owner può sempre editare** - Rimosso limite 5 minuti per owner/admin
6. **Eventi duplicati** - Hash universale basato su titolo+data/ora (senza organizer)
7. **Privacy dashboard Feste & Eventi** - Animatore vede solo propri commenti finanziari (non quelli degli altri)
8. **Navigazione "Vai all'evento"** - Fix ricerca evento tramite hash universale + uso `originalEventId` per navigazione
9. **Sistema Agenzia completo** - Nuove tabelle `agency_members`, `agency_calendar_access`, gestione inviti/permessi
10. **Bacheca/Colleghi non visibili per animatore** - Fix: `state.organization` non veniva aggiornato dopo accettazione invito. L'animatore restava con la sua vecchia org personale, veniva identificato come `isOrgOwner=true` e la card non veniva mostrata. Aggiunto refresh forzato di `state.organization` in `loadAgencyData()` e `loadMyAgencyFullData()`.

### Sistema Agenzia (AGGIORNATO 2026-01-29)

**File SQL**:
- `sql/09-agency-system.sql` - Schema base (tabelle, funzioni, trigger)
- `sql/10-fix-agency-rls.sql` - Fix RLS policies (evita ricorsione infinita)
- `sql/11-fix-accept-invite.sql` - Fix funzione accept_agency_invite (mapping ruoli)
- `sql/13-context-switcher.sql` - Context switcher per switch workspace (DA ESEGUIRE)
- `sql/14-agency-announcements.sql` - Sistema annunci bacheca (DA ESEGUIRE)

**Tabelle**:
- `agency_members` - Membri dell'agenzia con ruoli e permessi granulari
- `agency_calendar_access` - Calendari assegnati a ogni membro
- `agency_invites_log` - Log di inviti/revoche per audit

**Mapping Ruoli** (agency_members.role → profiles.org_role):
- `animator` → `member` (check constraint su profiles ammette solo: owner, admin, member, viewer)
- `admin` → `admin`
- `owner` → `owner`
- `viewer` → `member`

**Funzioni JS chiave**:
- `isAgencyOwnerOrAdmin()` - Verifica se utente è owner/admin
- `canSeeAllFinances()` - Verifica permesso vedere tutti i dati finanziari
- `getMyAgencyPermissions()` - Ottiene permessi granulari dell'utente
- `loadAgencyData()` - Carica membri e inviti
- `loadMyAgencyFullData()` - Carica dati completi per animatore (colleghi, calendari, bacheca)
- `sendAnimatorInvite()` - Invia invito a nuovo animatore (con condivisione automatica calendari Google)
- `checkAndAcceptInvite()` - Accetta invito da URL (#invite=token)
- `acceptInviteWithToken()` - Chiama RPC `accept_agency_invite` e mostra modal benvenuto
- `showWelcomeToAgencyModal()` - Modal di benvenuto dopo accettazione invito
- `shareCalendarsWithUser()` - Condivide calendari Google automaticamente con ACL
- `createCalendarForAnimator()` - Crea nuovo calendario da assegnare

**Flusso Invito**:
1. Capo agenzia va su TEAM > Gestione Agenzia
2. Clicca "Invita Animatore", inserisce email, ruolo, permessi
3. Seleziona calendari da condividere (condivisione automatica Google Calendar)
4. Riceve link da condividere (es. `#invite=token-uuid`)
5. Animatore clicca link, fa login/registrazione
6. Token salvato in localStorage durante auth flow
7. Dopo login, `checkPendingInvite()` chiama `accept_agency_invite` RPC
8. RPC aggiorna: agency_members.status='active', profiles.organization_id, profiles.org_role
9. Modal benvenuto con opzioni "Vai alla Home" / "Vai al Team"
10. Animatore vede card "La Mia Agenzia" con colleghi, calendari, bacheca

**Card "La Mia Agenzia" (per animatori)**:
- Header con nome agenzia, ruolo, data iscrizione
- Sezione Bacheca Annunci (messaggio di benvenuto)
- Sezione "I Miei Colleghi" con avatar e ruoli
- Sezione "I Miei Calendari" assegnati

### Context Switcher (NUOVO 2026-01-29)

L'utente può avere SIA il suo workspace personale SIA appartenere a un'agenzia.
Nel dropdown profilo (header) appare un selettore per switchare tra i workspace disponibili.

**File SQL**: `sql/13-context-switcher.sql`
- Aggiunge campo `current_context_org_id` in profiles
- Funzione RPC `get_user_organizations(p_user_id)` - lista workspace accessibili
- Funzione RPC `switch_organization_context(p_user_id, p_org_id)` - cambia contesto

**Funzioni JS chiave**:
- `loadUserWorkspaces()` - Carica lista workspace via RPC
- `renderContextSwitcher()` - Renderizza dropdown nel profilo
- `switchWorkspaceContext(orgId)` - Cambia contesto e ricarica dati
- `refreshCurrentPageData()` - Ricarica dati dopo cambio contesto

**Logica**:
- Ogni utente ha il suo workspace personale (creato alla registrazione)
- Può anche appartenere a una o più agenzie
- `current_context_org_id` indica quale workspace è attivo
- Se null, usa `organization_id` (default)
- Al cambio contesto, i dati vengono filtrati per l'organizzazione selezionata

**Problemi Noti da Risolvere**:
- [x] ~~Animatore non vede colleghi~~ - FIXATO (bug era in `state.organization` stale)
- [x] ~~Bacheca non mostra contenuto~~ - FIXATO (stesso problema di `state.organization`)
- [ ] Revoca animatore non revoca accesso calendario Google (DA IMPLEMENTARE)

### Da Completare / Testare

- [x] **ESEGUIRE SQL**: `sql/09-agency-system.sql` su Supabase (FATTO)
- [x] **ESEGUIRE SQL**: `sql/10-fix-agency-rls.sql` su Supabase (FATTO - FIX RLS policies)
- [x] **ESEGUIRE SQL**: `sql/11-fix-accept-invite.sql` su Supabase (FATTO - FIX mapping ruoli animator→member)
- [x] **Autenticazione unificata** - Token Google rinnovato tramite Supabase (COMPLETATO)
- [x] **Sistema inviti agenzia** - FUNZIONANTE (2026-01-29)
- [ ] Verificare unificazione commenti su eventi duplicati
- [ ] Testare flusso completo consegna compensi
- [ ] Testare modifica importo da owner e accetta/rifiuta da animatore
- [x] Click su evento dalla dashboard Feste & Eventi (FIXATO)
- [ ] Eventuale migrazione commenti vecchi con ID sbagliato
- [x] **Animatore non vede colleghi** - FIXATO: `state.organization` stale dopo accettazione invito
- [x] **Animatore non vede bacheca/benvenuto** - FIXATO: stesso problema
- [ ] **Revoca animatore → revoca accesso calendario Google** - DA IMPLEMENTARE
- [ ] **Integrare Stripe per upgrade piani** - IN AGENDA

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

CONTESTO: Sistema Compensi Agenzia per animatori in SAVERS PRO.

PROBLEMA RISOLTO: Eventi duplicati su calendari diversi ora unificati tramite hash(titolo+data/ora)

CAMPI CHIAVE nei commenti finanziari:
- incomeTotal: Ritiro Saldo totale
- animatorProfit: Guadagno animatore
- animatorExpenses: Spese animatore
- agencyFee: Compensi Agenzia

PERMESSI:
- Owner/Admin: vede TUTTI i commenti, può sempre editare/eliminare
- Animatore: vede solo propri commenti, edita entro 5 minuti

DA TESTARE:
1. Unificazione commenti eventi duplicati su calendari diversi
2. Calcoli corretti nelle viste (Agenzia vs Animatore)
3. Flusso consegna compensi

FILE PRINCIPALE: /Users/ilmagicartista/Downloads/savers pro per la vendita/index.html
```
