# Gestore Finanze V11

App Android-first per la gestione personale delle finanze, locale-first.

## Funzioni
- onboarding guidato con stipendio previsto/effettivo, giorno accredito, saldo e scoperto;
- movimenti manuali di spesa ed entrata;
- budget per categoria con avvisi di ritmo di spesa;
- spese ricorrenti normalizzate su base mensile;
- obiettivi di risparmio;
- sezione investimenti separata per ETF, azioni e crypto;
- analisi descrittive, concentrazione, rischio e scenari;
- piano prudente per recupero dallo scoperto;
- assistente contestuale locale;
- apertura assistita di Revolut, senza API, senza trasferimenti automatici;
- dati persistiti in SQLite sul dispositivo.

## Privacy / Revolut
Questa versione NON usa accesso alle notifiche, NON usa NotificationListener e NON richiede permessi per leggere notifiche. Non importa automaticamente transazioni da Revolut e non effettua movimenti bancari o ordini di investimento.

## Build
Richiede Flutter stable e Android SDK. Il workflow GitHub incluso prepara il progetto Android e costruisce l'APK release.
