# --- ÉTAPE 1 : Compilation (Build) ---
FROM dart:stable AS build

WORKDIR /app

# Copier les fichiers de dépendances
COPY pubspec.* ./

# Télécharger les packages DANS le projet (pas dans le cache global)
RUN dart pub get --no-precompile

# Copier tout le code source
COPY . .

# Re-lancer pub get pour s'assurer que tout est lié
RUN dart pub get

# Compiler en exécutable
RUN dart compile exe bin/main.dart -o bin/server

# --- ÉTAPE 2 : Exécution ---
FROM debian:bullseye-slim

WORKDIR /app

COPY --from=build /app/bin/server /app/server

EXPOSE 8081

CMD ["/app/server"]