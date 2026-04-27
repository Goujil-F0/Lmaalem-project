import 'dart:io';
import 'dart:convert';

void main() async {
  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8081);
  print('🚀 Serveur Maalem lancé sur le port ${server.port}');

  await for (HttpRequest request in server) {
    // Autoriser les requêtes depuis Flutter
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

Future<void> handleRegister(HttpRequest request) async {
  // On va remplir cette fonction ensemble
  request.response
    ..statusCode = HttpStatus.ok
    ..write(jsonEncode({'message': 'Register - bientôt disponible'}))
    ..close();
}

Future<void> handleLogin(HttpRequest request) async {
  // On va remplir cette fonction ensemble
  request.response
    ..statusCode = HttpStatus.ok
    ..write(jsonEncode({'message': 'Login - bientôt disponible'}))
    ..close();
}