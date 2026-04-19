# --- ÉTAPE 1 : Compilation (Build) ---
# On utilise l'image officielle Dart pour compiler le code
FROM dart:stable AS build

# Définir le dossier de travail dans le conteneur
WORKDIR /app

# Copier les fichiers de dépendances et les installer
# On fait ça avant de copier tout le code pour optimiser le cache Docker
COPY pubspec.* ./
RUN dart pub get

# Copier tout le reste du code source du serveur
COPY . .

# Compiler le programme Dart en un exécutable machine (plus rapide et plus léger)
# On compile le fichier bin/main.dart et on l'appelle 'server'
RUN dart compile exe bin/main.dart -o bin/server

# ÉTAPE 2 : Exécution (On utilise l'image Dart pour être sûr d'avoir toutes les libs)
FROM dart:stable
WORKDIR /app
COPY --from=build /app/bin/server /app/server

EXPOSE 8081

# On lance l'exécutable
CMD ["/app/server"]