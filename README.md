# SpesApp 🛒

SpesApp è un'applicazione Flutter progettata per semplificare e velocizzare l'esperienza della spesa. Permette di gestire liste della spesa in tempo reale, con rilevamento automatico del supermercato tramite GPS e gestione intelligente dei prezzi e delle promozioni.

## 🚀 Funzionalità Principali

*   **Rilevamento Automatico Supermercato**: Utilizza il GPS per identificare il punto vendita corrente e suggerire i prezzi corrispondenti.
*   **Inserimento Ultra-Rapido**: Interfaccia ottimizzata per aggiungere prodotti al carrello durante la spesa con pochissimi tap.
*   **Gestione Prezzi e Storico**: Mantiene traccia dei prezzi per ogni punto vendita e avvisa se un prezzo non viene aggiornato da tempo.
*   **Promozioni**: Gestione delle promozioni con date di validità e tipologia di sconto.
*   **Feedback Errori Interattivo**: Icone di stato cliccabili per capire subito eventuali anomalie (es. prodotto non censito nel negozio corrente).

## 🛠️ Requisiti

Prima di iniziare, assicurati di avere installato:

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (versione >= 3.10.8)
*   [Node.js](https://nodejs.org/) (necessario per la gestione del versioning e del changelog)
*   Un emulatore Android/iOS o un dispositivo fisico configurato per il debug.

## 📦 Installazione

1.  **Clona il repository**:
    ```bash
    git clone https://github.com/mirkocolombo1994/FlutterSpesApp.git
    cd FlutterSpesApp
    ```

2.  **Installa le dipendenze Flutter**:
    ```bash
    flutter pub get
    ```

3.  **Installa le dipendenze Node.js (per sviluppatori)**:
    ```bash
    npm install
    ```

## 🏃 Avvio in Locale

Per avviare l'applicazione in modalità debug:

```bash
flutter run
```

## 🏷️ Versioning e Rilascio

Il progetto utilizza `standard-version` per gestire il versioning semantico e la generazione automatica del `CHANGELOG.md`.

*   **Per creare una nuova versione**:
    ```bash
    npm run release
    ```
    *Questo comando incrementa la versione in `pubspec.yaml`, aggiorna il `CHANGELOG.md` e crea un tag Git.*

*   **Per generare l'APK di produzione**:
    ```bash
    flutter build apk --release
    ```

## 🏗️ Architettura

*   **State Management**: [Riverpod](https://riverpod.dev/)
*   **Database Locale**: [sqflite](https://pub.dev/packages/sqflite)
*   **Mappe e GPS**: [flutter_map](https://pub.dev/packages/flutter_map) e [geolocator](https://pub.dev/packages/geolocator)
