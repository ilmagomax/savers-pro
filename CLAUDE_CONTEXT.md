# SAVERS PRO - Context File per Claude Code
> Aggiornato: 2026-01-28 - FASE 2 in corso (Habits + Tasks completati)

## STATO PROGETTO

### Completato
- [x] FASE 0: Setup Progetto (GitHub, Vercel, CSS estratto)
- [x] FASE 1: Auth Migration a Supabase (Google OAuth funzionante)
- [x] RLS Policies fixate (profiles + organizations)
- [x] Habits + Habit Logs migrati a Supabase
- [x] Tasks migrati a Supabase

### In Corso - FASE 2: Migrazione Dati Personali
Migrazione dei moduli da `state.habits/tasks/...` (attualmente sincronizzati con Google Sheets) a Supabase:
- [x] Habits + Habit Logs (COMPLETATO 2026-01-28)
- [x] Tasks (COMPLETATO 2026-01-28)
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
├── index.html              # App principale (~27k righe)
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

## MODULI MIGRATI

### HABITS (riga ~4375 in index.html)
```javascript
loadHabitsFromDB()         // Carica habits da Supabase
saveHabitToDB(habit)       // Salva nuova habit
updateHabitInDB(id, data)  // Aggiorna habit esistente
deleteHabitFromDB(id)      // Soft delete (is_active=false)
toggleHabitInDB(id, date)  // Log completamento
updateHabitStreakInDB(id)  // Calcola streak server-side
loadHabitsFromSupabase()   // Chiamata da ensureUserProfile()
migrateLocalHabitsToSupabase() // Migrazione one-time
```

### TASKS (riga ~4808 in index.html)
```javascript
loadTasksFromDB()          // Carica tasks da Supabase
saveTaskToDB(task)         // Salva nuovo task
updateTaskInDB(id, data)   // Aggiorna task esistente
deleteTaskFromDB(id)       // Hard delete
toggleTaskInDB(id, done)   // Toggle completamento
loadTasksFromSupabase()    // Chiamata da ensureUserProfile()
migrateLocalTasksToSupabase() // Migrazione one-time
```

### Pattern di caricamento dati (ensureUserProfile)
```javascript
// Load data from Supabase (habits and tasks in parallel)
await Promise.all([
    loadHabitsFromSupabase(),
    loadTasksFromSupabase()
]);
```

---

## PROSSIMO MODULO: TRANSACTIONS

### Schema DB (sql/01-base-schema.sql righe 217-243)
```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    amount DECIMAL(12,2) NOT NULL,
    currency TEXT DEFAULT 'EUR',
    description TEXT,
    category TEXT NOT NULL,
    date DATE NOT NULL,
    department TEXT DEFAULT 'personal',
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_rule TEXT,
    receipt_url TEXT,
    payment_method TEXT,
    payment_status TEXT DEFAULT 'completed',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Funzioni da cercare
- Cerca `saveTransaction()` o simili
- Cerca dove vengono renderizzate le transazioni (Finance page)
- Cerca `state.transactions`

---

## NOTE PER NUOVA CHAT

Quando apri una nuova chat, usa questo prompt:

```
Leggi /Users/ilmagicartista/Downloads/savers pro per la vendita/CLAUDE_CONTEXT.md
e continua con la FASE 2: Migrazione Dati Personali.

Prossimo modulo: TRANSACTIONS
1. Cerca le funzioni esistenti per transactions in index.html
2. Aggiungi le funzioni CRUD Supabase
3. Modifica le funzioni esistenti per salvare su Supabase
4. Aggiungi caricamento in ensureUserProfile()
5. Testa e fai deploy

Usa il metodo Ralph Loop - aggiorna CLAUDE_CONTEXT.md al termine.
```

---

## PROMISE TAGS

- [x] FASE0_COMPLETE
- [x] FASE1_AUTH_COMPLETE
- [ ] FASE2_PERSONAL_DATA_COMPLETE (Habits done, Tasks done, Transactions next)
- [ ] FASE3_TEAM_COMPLETE
- [ ] FASE4_COURSES_COMPLETE
- [ ] FASE5_SHOP_COMPLETE
- [ ] FASE6_PUSH_COMPLETE
