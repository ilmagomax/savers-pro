# SAVERS PRO - Context File per Claude Code
> Aggiornato: 2026-01-28 - FASE 2 COMPLETATA

## STATO PROGETTO

### Completato
- [x] FASE 0: Setup Progetto (GitHub, Vercel, CSS estratto)
- [x] FASE 1: Auth Migration a Supabase (Google OAuth funzionante)
- [x] RLS Policies fixate (profiles + organizations)
- [x] **FASE 2: Migrazione Dati Personali COMPLETATA**
  - [x] Habits + Habit Logs
  - [x] Tasks
  - [x] Transactions
  - [x] Books
  - [x] Goals
  - [x] Notes
  - [x] SAVERS Logs
  - [x] Pomodoro Sessions

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
    loadSaversLogsFromSupabase()
]);
```

### Funzioni CRUD per modulo (righe ~4375-5400)

**HABITS**: loadHabitsFromDB, saveHabitToDB, updateHabitInDB, deleteHabitFromDB, toggleHabitInDB

**TASKS**: loadTasksFromDB, saveTaskToDB, updateTaskInDB, deleteTaskFromDB, toggleTaskInDB

**TRANSACTIONS**: loadTransactionsFromDB, saveTransactionToDB, deleteTransactionFromDB

**BOOKS**: loadBooksFromDB, saveBookToDB, updateBookInDB, deleteBookFromDB

**GOALS**: loadGoalsFromDB, saveGoalToDB, updateGoalInDB, deleteGoalFromDB

**NOTES**: loadNotesFromDB, saveNoteToDB, updateNoteInDB, deleteNoteFromDB

**SAVERS LOGS**: loadSaversLogsFromDB, saveSaversLogToDB

**POMODORO**: savePomodoroSessionToDB, loadPomodoroStatsFromDB

---

## PROSSIMA FASE: TEAM & PROGETTI

### Elementi da implementare
1. Tabelle esistenti: `organizations`, `profiles` (con org_role)
2. Necessario creare: `team_projects`, `project_tasks`, `project_members`
3. Funzionalità: invite members, assign tasks, project boards

### Schema suggerito
```sql
CREATE TABLE team_projects (
    id UUID PRIMARY KEY,
    organization_id UUID REFERENCES organizations(id),
    name TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'active',
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE project_members (
    project_id UUID REFERENCES team_projects(id),
    user_id UUID REFERENCES profiles(id),
    role TEXT DEFAULT 'member',
    PRIMARY KEY (project_id, user_id)
);
```

---

## NOTE PER NUOVA CHAT

```
Leggi /Users/ilmagicartista/Downloads/savers pro per la vendita/CLAUDE_CONTEXT.md
e continua con FASE 3: Team & Progetti.

1. Crea lo schema SQL per team_projects e project_members
2. Aggiungi funzioni CRUD per progetti team
3. Modifica le funzioni esistenti di team/progetti
4. Implementa invite system
5. Testa e deploy

Usa il metodo Ralph Loop.
```

---

## PROMISE TAGS

- [x] FASE0_COMPLETE
- [x] FASE1_AUTH_COMPLETE
- [x] FASE2_PERSONAL_DATA_COMPLETE
- [ ] FASE3_TEAM_COMPLETE
- [ ] FASE4_COURSES_COMPLETE
- [ ] FASE5_SHOP_COMPLETE
- [ ] FASE6_PUSH_COMPLETE
