# SAVERS PRO - Context File per Claude Code
> Aggiornato: 2026-01-28 - FASE 2 COMPLETATA

## STATO PROGETTO

### Completato
- [x] FASE 0: Setup Progetto (GitHub, Vercel, CSS estratto)
- [x] FASE 1: Auth Migration a Supabase (Google OAuth funzionante)
- [x] RLS Policies fixate (profiles + organizations)
- [x] **FASE 2: Migrazione Dati Personali** - COMPLETATA
  - [x] Habits + Habit Logs
  - [x] Tasks
  - [x] Transactions (CRUD + edit/delete modal funzionante)
  - [x] Books (testato - funzionante)
  - [x] Goals (testato - funzionante)
  - [x] Notes (testato - funzionante)
  - [x] SAVERS Logs
  - [x] Pomodoro Sessions
  - [x] Money Goals (testato - funzionante con Supabase)

### Bug Risolti (2026-01-28)

1. **Fix showModal function** - La funzione `showModal()` non mostrava i modal dinamici perché creava un `<div class="modal">` invece di `<div class="modal-overlay"><div class="modal">...</div></div>`. Fixato in commit 783ed9f.

2. **Money Goals** - Tabella già presente in Supabase, modulo testato e funzionante

### Da Fare (Prossime Fasi)
- [ ] FASE 3: Team & Progetti
- [ ] FASE 4: Videocorsi (con link a GHL/Arcanis)
- [ ] FASE 5: Shop (con link a GHL/Arcanis)
- [ ] FASE 6: Push Notifications
- [ ] FASE 7: PWA Optimization
- [ ] FASE 8: Directus CMS Setup

---

## CONFIGURAZIONE

### Repository
- **GitHub**: https://github.com/ilmagomax/savers-pro
- **Vercel**: https://savers-pro.vercel.app
- **Branch**: main

### Supabase
- **URL**: https://lsrzcsymiuoutcmhcain.supabase.co
- **Anon Key**: sb_publishable_NFzbjbgsGgEn5enQg7M2VQ_XJoFb9RM
- **Site URL**: https://savers-pro.vercel.app

---

## MODULI MIGRATI A SUPABASE

### Pattern di caricamento (ensureUserProfile ~riga 4720)
```javascript
await Promise.all([
    loadHabitsFromSupabase(),
    loadTasksFromSupabase(),
    loadTransactionsFromSupabase(),
    loadBooksFromSupabase(),
    loadGoalsFromSupabase(),
    loadNotesFromSupabase(),
    loadSaversLogsFromSupabase(),
    loadMoneyGoalsFromSupabase()  // NUOVO
]);
```

### Funzioni CRUD per modulo (righe ~4375-5600)

**HABITS**: loadHabitsFromDB, saveHabitToDB, updateHabitInDB, deleteHabitFromDB, toggleHabitInDB

**TASKS**: loadTasksFromDB, saveTaskToDB, updateTaskInDB, deleteTaskFromDB, toggleTaskInDB

**TRANSACTIONS**: loadTransactionsFromDB, saveTransactionToDB, updateTransactionInDB, deleteTransactionFromDB

**BOOKS**: loadBooksFromDB, saveBookToDB, updateBookInDB, deleteBookFromDB

**GOALS**: loadGoalsFromDB, saveGoalToDB, updateGoalInDB, deleteGoalFromDB

**NOTES**: loadNotesFromDB, saveNoteToDB, updateNoteInDB, deleteNoteFromDB

**MONEY GOALS** (NUOVO): loadMoneyGoalsFromDB, saveMoneyGoalToDB, updateMoneyGoalInDB, deleteMoneyGoalFromDB

**SAVERS LOGS**: loadSaversLogsFromDB, saveSaversLogToDB

**POMODORO**: savePomodoroSessionToDB, loadPomodoroStatsFromDB

---

## NOTE PER NUOVA CHAT

```
Leggi /Users/ilmagicartista/Downloads/savers pro per la vendita/CLAUDE_CONTEXT.md

FASE 2 COMPLETATA - Tutti i moduli personali funzionano:
- Habits, Tasks, Transactions, Books, Goals, Notes, Money Goals

PROSSIMA PRIORITA': FASE 3 - Team & Progetti
- Migrazione funzionalità team a Supabase
- Progetti condivisi con membri del team
```

---

## EXTRA: DA COMPLETARE IN FUTURO

### Google Tasks Sync (Disabilitato temporaneamente)
- **Problema**: Richiede lo scope `https://www.googleapis.com/auth/tasks` che non è incluso nell'OAuth Supabase
- **Soluzione**:
  1. Vai su **Supabase Dashboard** → **Authentication** → **Providers** → **Google**
  2. Aggiungi questi scopes:
     ```
     https://www.googleapis.com/auth/tasks
     https://www.googleapis.com/auth/tasks.readonly
     ```
  3. Gli utenti dovranno ri-autenticarsi per ottenere i nuovi permessi
- **File**: `loadGoogleTaskLists()` chiamate commentate in index.html

### Backend Legacy (Disabilitato)
- **getUserNotifications** - Vecchio backend Google Sheets, sarà migrato a Supabase
- **getUserTeams** - Vecchio backend Google Sheets, sarà migrato a Supabase
- **File**: Funzioni disabilitate in index.html, da riabilitare dopo migrazione a Supabase

---

## PROMISE TAGS

- [x] FASE0_COMPLETE
- [x] FASE1_AUTH_COMPLETE
- [x] FASE2_PERSONAL_DATA_COMPLETE
- [ ] FASE3_TEAM_COMPLETE
- [ ] FASE4_COURSES_COMPLETE
- [ ] FASE5_SHOP_COMPLETE
- [ ] FASE6_PUSH_COMPLETE
- [ ] EXTRA_GOOGLE_TASKS_SYNC
