# Procedura di Rilascio SpesApp

Questa guida descrive i passaggi dettagliati per pubblicare una nuova versione dell'applicazione, garantendo la sincronia tra i branch `develop` e `main` e la creazione di una release ufficiale sul repository.

## Pre-requisiti
- Sei sul branch `develop`.
- Tutti i cambiamenti sono stati testati e sono pronti per il rilascio.

---

## Passaggi per il Rilascio

### 1. Aggiornamento Versione
Aggiorna il file `pubspec.yaml` incrementando il numero di versione e il build number:
- Esempio: `0.3.0+6` dove `0.3.0` è la versione semantica e `6` è il build progressivo.

### 2. Consolidamento su Develop
Esegui il commit di tutte le modifiche (incluso l'aggiornamento di `pubspec.yaml`) sul branch `develop`.
```bash
git add .
git commit -m "feat: [Descrizione breve della feature]"
git push origin develop
```

### 3. Allineamento Branch Main
Prima di fondere i cambiamenti, assicurati che il branch `main` locale sia aggiornato rispetto al server:
```bash
git checkout main
git pull origin main
```
> [!IMPORTANT]
> Non saltare il `git pull origin main` per evitare errori di caricamente (push fallito per branch dietro il server).

### 4. Merge e Push Finale
Fondi le novità di `develop` su `main` e invia tutto sul server:
```bash
git merge develop
git push origin main
```

### 5. Creazione Release (Tag)
Crea un "Tag annotato" per marcare la versione nel repository GitHub:
```bash
git tag -a v0.3.0 -m "Release v0.3.0: Descrizione sintetica"
git push origin v0.3.0
```

### 6. Ritorno allo Sviluppo
Torna sul branch `develop` per proseguire il lavoro:
```bash
git checkout develop
```

---

## Troubleshooting Comuni
- **Push Fallito (Updates Rejected)**: Significa che qualcuno ha pushato sul server prima di te. Esegui `git pull origin main --rebase` e riprova il push.
- **Conflitti di Merge**: Se ci sono file modificati sia su `develop` che su `main`, git ti chiederà di risolverli manualmente prima di completare il commit di merge.
