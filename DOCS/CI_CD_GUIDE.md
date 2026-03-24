# Guida al Rilascio e Firma dell'APK

Questa guida spiega come configurare la firma dell'APK per il rilascio in sicurezza sul Google Play Store e come funziona la pipeline CI/CD.

## Pipeline CI/CD (GitHub Actions)

La pipeline è definita in `.github/workflows/ci_cd.yml` e segue questa logica:
1.  **Ogni Push**: Esegue `flutter test` su qualsiasi branch.
2.  **Release (GitHub)**:
    *   Esegue i test.
    *   Genera l'APK release.
    *   Carica l'APK come asset nella release.
    *   Esegue il merge automatico del branch nel branch `main`.

## Come Firmare l'APK (Play Store)

Al momento la pipeline genera un APK non firmato. Per caricarlo sul Play Store, segui questi passaggi:

### 1. Genera un Keystore
Esegui questo comando in locale (sostituisci `my-release-key` con un nome a tua scelta):
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2. Configura i Secrets su GitHub
Vai nelle impostazioni del tuo repository su GitHub -> **Settings** -> **Secrets and variables** -> **Actions** e aggiungi i seguenti segreti:
*   `KEYSTORE_BASE64`: Il contenuto del file `.jks` convertito in base64.
*   `KEYSTORE_PASSWORD`: La password del keystore.
*   `KEY_ALIAS`: L'alias della chiave (es. `upload`).
*   `KEY_PASSWORD`: La password della chiave.

### 3. Aggiorna la Pipeline
Dovrai aggiungere uno step nella pipeline per decodificare il keystore e configurare Flutter per usarlo (creando un file `key.properties` al volo).

Esempio di step da aggiungere prima di `flutter build apk`:
```yaml
- name: Decode Keystore
  run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/upload-keystore.jks

- name: Create key.properties
  run: |
    echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
    echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
    echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
    echo "storeFile=upload-keystore.jks" >> android/key.properties
```

---
> [!IMPORTANT]
> Non caricare mai il file `.jks` o `key.properties` direttamente su Git! Usa sempre i Secrets di GitHub.
