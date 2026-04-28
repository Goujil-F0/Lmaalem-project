import 'dart:io';
import 'package:postgres/postgres.dart';

class Database {
  static Connection? _connection;

  // Connexion à PostgreSQL
  static Future<Connection> get connection async {
    if (_connection != null) return _connection!;

    _connection = await Connection.open(
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? 'localhost',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME'] ?? 'maalem_db',
        username: Platform.environment['DB_USER'] ?? 'maalem_user',
        password: Platform.environment['DB_PASSWORD'] ?? 'maalem_pass',
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.disable,
      ),
    );

    print('✅ Connecté à PostgreSQL !');
    return _connection!;
  }
}