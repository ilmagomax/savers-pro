# SAVERS PRO - Context File per Claude Code
> Aggiornato: 2026-01-28 - BUG FIX IN CORSO

## STATO PROGETTO

### Completato
- [x] FASE 0: Setup Progetto (GitHub, Vercel, CSS estratto)
- [x] FASE 1: Auth Migration a Supabase (Google OAuth funzionante)
- [x] RLS Policies fixate (profiles + organizations)
- [x] **FASE 2: Migrazione Dati Personali** (parzialmente - vedi bug)
  - [x] Habits + Habit Logs
  - [x] Tasks
  - [x] Transactions (CRUD + edit modal aggiunto)
  - [x] Books
  - [x] Goals
  - [x] Notes
  - [x] SAVERS Logs
  - [x] Pomodoro Sessions
  - [x] Money Goals (NUOVO - CRUD aggiunto)

### BUG CRITICI DA RISOLVERE (PROSSIMA SESSIONE)

1. **Pagina vuota dopo login** - La pagina mostra solo "// Deploy trigger 1769624005" invece del contenuto
   - Probabile errore JavaScript che blocca il rendering
   - Controllare console per errori

2. **Money Goals migration** - Eseguire `sql/04-money-goals.sql` in Supabase Dashboard

3. **Service Worker cache** - Dopo fix, fare hard refresh (Cmd+Shift+R) per aggiornare

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

PRIORITA' 1: Fix bug pagina vuota
1. Apri https://savers-pro.vercel.app con DevTools console aperta
2. Identifica l'errore JavaScript che blocca il rendering
3. Il contenuto della pagina non viene mostrato, solo "// Deploy trigger"

PRIORITA' 2: Esegui migration Money Goals
1. Vai su Supabase Dashboard > SQL Editor
2. Esegui il contenuto di sql/04-money-goals.sql

PRIORITA' 3: Test moduli
- Habits (funziona)
- Tasks (funziona)
- Transactions (testare edit/delete)
- Books (da testare)
- Goals (da testare)
- Notes (da testare)
- Money Goals (da testare dopo migration)

Usa il metodo Ralph Loop.
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
- [ ] FASE2_PERSONAL_DATA_COMPLETE (bug da fixare)
- [ ] FASE3_TEAM_COMPLETE
- [ ] FASE4_COURSES_COMPLETE
- [ ] FASE5_SHOP_COMPLETE
- [ ] FASE6_PUSH_COMPLETE
- [ ] EXTRA_GOOGLE_TASKS_SYNC
