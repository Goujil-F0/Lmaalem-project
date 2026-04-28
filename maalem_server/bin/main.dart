import 'dart:io';
import 'dart:convert';
import '../lib/database/db.dart';
import '../lib/routes/auth_routes.dart';

void main() async {
  // Test connexion DB
  await Database.connection;

  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8081);
  print('🚀 Serveur Maalem lancé sur le port ${server.port}');

  await for (HttpRequest request in server) {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Content-Type', 'application/json');

    final path = request.uri.path;
    final method = request.method;

    print('📨 $method $path');

    if (method == 'POST' && path == '/auth/register') {
      await handleRegister(request);
    } else if (method == 'POST' && path == '/auth/login') {
      await handleLogin(request);
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write(jsonEncode({'error': 'Route non trouvée'}))
        ..close();
    }
  }
}
