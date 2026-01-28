# SAVERS PRO - Context File per Claude Code
> Aggiornato: 2026-01-28 - FASE 2 in corso (Habits completato)

## STATO PROGETTO

### Completato
- [x] FASE 0: Setup Progetto (GitHub, Vercel, CSS estratto)
- [x] FASE 1: Auth Migration a Supabase (Google OAuth funzionante)
- [x] RLS Policies fixate (profiles + organizations)
- [x] Habits + Habit Logs migrati a Supabase

### In Corso - FASE 2: Migrazione Dati Personali
Migrazione dei moduli da `state.habits/tasks/...` (attualmente sincronizzati con Google Sheets) a Supabase:
- [x] Habits + Habit Logs (COMPLETATO 2026-01-28)
- [ ] Tasks (personali)
- [ ] Transactions
- [ ] Books
- [ ] Goals
- [ ] SAVERS Logs
- [ ] Notes
- [ ] Pomodoro Sessions

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

### Google OAuth
- **Progetto**: SAVERS Pro
- **Status**: Testing mode
- **Redirect URI**: https://lsrzcsymiuoutcmhcain.supabase.co/auth/v1/callback

---

## STRUTTURA FILE

```
/Users/ilmagicartista/Downloads/savers pro per la vendita/
├── index.html              # App principale (~26k righe)
├── css/styles.css          # CSS estratto (8910 righe)
├── manifest.json           # PWA config
├── sw.js                   # Service Worker
├── vercel.json             # Deploy config
├── .gitignore
├── CLAUDE_CONTEXT.md       # Questo file
└── sql/
    ├── 01-base-schema.sql  # Schema DB base (eseguito)
    ├── 02-fix-rls-policies.sql  # RLS fix (eseguito)
    └── new-features.sql    # Schema per Videocorsi, Shop, Push
```

---

## HABITS - IMPLEMENTAZIONE COMPLETATA

### Funzioni CRUD aggiunte (riga ~4375 in index.html)
```javascript
loadHabitsFromDB()         // Carica habits da Supabase
saveHabitToDB(habit)       // Salva nuova habit
updateHabitInDB(id, data)  // Aggiorna habit esistente
deleteHabitFromDB(id)      // Soft delete (is_active=false)
toggleHabitInDB(id, date)  // Log completamento
updateHabitStreakInDB(id)  // Calcola streak server-side
```

### Funzioni di supporto
```javascript
loadHabitsFromSupabase()        // Chiamata da ensureUserProfile()
migrateLocalHabitsToSupabase()  // Migrazione one-time
```

### Modifiche effettuate
- `saveHabit()` ora salva su Supabase (async, con fallback locale)
- `toggleHabit()` ora sincronizza su habit_logs (async, non bloccante)
- `ensureUserProfile()` ora chiama `loadHabitsFromSupabase()` dopo il login

### Struttura dati state.habits (aggiornata)
```javascript
{
    id: 'uuid-from-supabase',      // UUID Supabase
    name: 'Meditare',
    icon: '🧘',
    frequency: 'daily',
    department: 'personal',
    streak: 5,
    bestStreak: 10,
    totalCompletions: 45,
    completedDates: ['2026-01-25', '2026-01-26'],
    scheduledTime: '07:00',
    createdAt: '2026-01-20T10:00:00Z',
    _supabaseId: 'uuid'            // Riferimento DB
}
```

---

## PROSSIMO MODULO: TASKS

### Analisi preliminare richiesta
Per migrare Tasks seguire lo stesso pattern di Habits:

1. **Funzioni CRUD da creare:**
   - `loadTasksFromDB()`
   - `saveTaskToDB(task)`
   - `updateTaskInDB(id, updates)`
   - `deleteTaskFromDB(id)`
   - `toggleTaskCompletionInDB(id, completed)`

2. **Funzioni esistenti da modificare:**
   - Cerca `saveTask()` o funzioni simili
   - Cerca `toggleTask()` o `completeTask()`
   - Trova dove vengono renderizzati i tasks

3. **Schema DB:** Tabella `tasks` già esiste (vedi sql/01-base-schema.sql righe 178-215)

---

## NOTE PER NUOVA CHAT

Quando apri una nuova chat, usa questo prompt:

```
Leggi /Users/ilmagicartista/Downloads/savers pro per la vendita/CLAUDE_CONTEXT.md
e continua con la FASE 2: Migrazione Dati Personali.

Prossimo modulo: TASKS
1. Analizza le funzioni esistenti per tasks in index.html
2. Aggiungi le funzioni CRUD Supabase (loadTasksFromDB, saveTaskToDB, etc.)
3. Modifica le funzioni esistenti per salvare su Supabase
4. Aggiungi caricamento tasks in loadHabitsFromSupabase() o simile
5. Testa e fai deploy

Usa il metodo Ralph Loop - aggiorna CLAUDE_CONTEXT.md al termine.
```

---

## PROMISE TAGS

- [x] FASE0_COMPLETE
- [x] FASE1_AUTH_COMPLETE
- [ ] FASE2_PERSONAL_DATA_COMPLETE (Habits done, Tasks next)
- [ ] FASE3_TEAM_COMPLETE
- [ ] FASE4_COURSES_COMPLETE
- [ ] FASE5_SHOP_COMPLETE
- [ ] FASE6_PUSH_COMPLETE
