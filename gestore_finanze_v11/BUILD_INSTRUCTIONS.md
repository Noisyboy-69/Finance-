# Build V11

1. Flutter stable.
2. `flutter pub get`
3. `flutter analyze`
4. `flutter build apk --release`

Se l'ambiente non contiene il wrapper Gradle, eseguire una sola volta `flutter create . --platforms=android` nella root del progetto prima della build. Non serve modificare `lib/`.

La versione finale non usa NotificationListener e non richiede accesso alle notifiche.
