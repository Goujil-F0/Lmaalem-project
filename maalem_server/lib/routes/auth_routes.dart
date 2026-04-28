import 'dart:io';
import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import '../database/db.dart';

Future<void> handleRegister(HttpRequest request) async {
  try {
    // 1. Lire le body JSON envoyé par Flutter
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body);

    // 2. Vérifier que les champs obligatoires sont présents
    final nom = data['nom'];
    final email = data['email'];
    final password = data['password'];
    final role = data['role'];

    if (nom == null || email == null || password == null || role == null) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'error': 'Champs manquants : nom, email, password, role'}))
        ..close();
      return;
    }

    // 3. Vérifier que le role est valide
    if (role != 'client' && role != 'artisan') {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'error': 'Role invalide. Choisir : client ou artisan'}))
        ..close();
      return;
    }

    // 4. Hasher le mot de passe
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    // 5. Insérer dans PostgreSQL
    final db = await Database.connection;
    final result = await db.execute(
      Sql.named(
        'INSERT INTO users (nom, email, password, role) '
        'VALUES (@nom, @email, @password, @role) '
        'RETURNING uid, nom, email, role, created_at'
      ),
      parameters: {
        'nom': nom,
        'email': email,
        'password': hashedPassword,
        'role': role,
      },
    );

    // 6. Récupérer l'utilisateur créé
    final user = result.first;

    // 7. Générer un token JWT
    final jwt = JWT({'uid': user[0], 'email': user[2], 'role': user[3]});
    final token = jwt.sign(
      SecretKey(Platform.environment['JWT_SECRET'] ?? 'secret'),
      expiresIn: Duration(days: 7),
    );

    // 8. Répondre avec le token et les infos user
    request.response
      ..statusCode = HttpStatus.created
      ..write(jsonEncode({
        'token': token,
        'user': {
          'uid': user[0],
          'nom': user[1],
          'email': user[2],
          'role': user[3],
        }
      }))
      ..close();

  } catch (e) {
    // Email déjà utilisé ou autre erreur
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write(jsonEncode({'error': e.toString()}))
      ..close();
  }
}

Future<void> handleLogin(HttpRequest request) async {
  try {
    // 1. Lire le body JSON
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body);

    final email = data['email'];
    final password = data['password'];

    // 2. Vérifier les champs
    if (email == null || password == null) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'error': 'Email et password obligatoires'}))
        ..close();
      return;
    }

    // 3. Chercher l'utilisateur dans PostgreSQL
    final db = await Database.connection;
    final result = await db.execute(
      Sql.named('SELECT uid, nom, email, password, role FROM users WHERE email = @email'),
      parameters: {'email': email},
    );

    // 4. Vérifier que l'utilisateur existe
    if (result.isEmpty) {
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..write(jsonEncode({'error': 'Email ou mot de passe incorrect'}))
        ..close();
      return;
    }

    final user = result.first;

    // 5. Vérifier le mot de passe
    final isValid = BCrypt.checkpw(password, user[3] as String);
    if (!isValid) {
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..write(jsonEncode({'error': 'Email ou mot de passe incorrect'}))
        ..close();
      return;
    }

    // 6. Générer le token JWT
    final jwt = JWT({'uid': user[0], 'email': user[2], 'role': user[4]});
    final token = jwt.sign(
      SecretKey(Platform.environment['JWT_SECRET'] ?? 'secret'),
      expiresIn: Duration(days: 7),
    );

    // 7. Répondre
    request.response
      ..statusCode = HttpStatus.ok
      ..write(jsonEncode({
        'token': token,
        'user': {
          'uid': user[0],
          'nom': user[1],
          'email': user[2],
          'role': user[4],
        }
      }))
      ..close();

  } catch (e) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write(jsonEncode({'error': e.toString()}))
      ..close();
  }
}