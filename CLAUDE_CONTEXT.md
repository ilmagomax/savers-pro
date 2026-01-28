# SAVERS PRO - Context File per Claude Code
> Aggiornato: 2026-01-28

## STATO PROGETTO

### Completato
- [x] Piano dettagliato approvato
- [x] Repository GitHub creato: https://github.com/ilmagomax/savers-pro
- [x] Struttura cartelle base
- [x] File configurazione (.gitignore, .env.example, vercel.json)
- [x] index.html copiato da savers-pro-v5.html
- [x] manifest.json e sw.js copiati

### In Corso
- [ ] FASE 0: Setup Supabase integration

### Da Fare
- [ ] FASE 1: Auth Migration
- [ ] FASE 2: Migrazione Dati Personali
- [ ] FASE 3: Team & Progetti
- [ ] FASE 4: Videocorsi
- [ ] FASE 5: Shop
- [ ] FASE 6: Push Notifications
- [ ] FASE 7: PWA Optimization
- [ ] FASE 8: Directus CMS Setup

---

## CONFIGURAZIONE

### Repository
- **GitHub**: https://github.com/ilmagomax/savers-pro
- **Branch**: main
- **Deploy Target**: Vercel

### Supabase
- **URL**: DA CONFIGURARE
- **Anon Key**: DA CONFIGURARE
- **Region**: Frankfurt (eu-central-1)

### Tecnologie
- Frontend: HTML/CSS/JS (single file, poi modularizzato)
- Backend: Supabase (Auth, Database, Realtime)
- PWA: manifest.json + sw.js
- Push: Web Push API + OneSignal (opzionale)
- CMS: Directus (self-hosted)

---

## FASI RALPH LOOP

### FASE 0: Setup Progetto ⏳
```
Promise: FASE0_COMPLETE
Status: IN PROGRESS
```
Tasks:
- [x] Creare struttura cartelle
- [x] Copiare file esistenti
- [x] Creare repo GitHub
- [ ] Estrarre CSS in file separato
- [ ] Aggiungere Supabase client
- [ ] Verificare console "Supabase initialized: OK"

### FASE 1: Auth Migration
```
Promise: FASE1_AUTH_COMPLETE
Status: PENDING
```

### FASE 2: Migrazione Dati
```
Promise: FASE2_PERSONAL_DATA_COMPLETE
Status: PENDING
```

### FASE 3: Team & Progetti
```
Promise: FASE3_TEAM_COMPLETE
Status: PENDING
```

### FASE 4: Videocorsi
```
Promise: FASE4_COURSES_COMPLETE
Status: PENDING
```

### FASE 5: Shop
```
Promise: FASE5_SHOP_COMPLETE
Status: PENDING
```

### FASE 6: Push Notifications
```
Promise: FASE6_PUSH_COMPLETE
Status: PENDING
```

---

## NOTE PER PROSSIMA CHAT

Se questa chat raggiunge il limite di contesto, apri nuova chat con:

```
Leggi /Users/ilmagicartista/Downloads/savers pro per la vendita/CLAUDE_CONTEXT.md
e continua da dove eri rimasto. Usa il metodo Ralph Loop.
```

---

## FILE IMPORTANTI

- `/index.html` - App principale
- `/manifest.json` - PWA config
- `/sw.js` - Service Worker
- `/sql/new-features.sql` - Schema nuove tabelle
- `/SAVERS-PRO-COMPLETE-GUIDE.md` - Guida completa originale
