import 'dart:io';

void main() async {
  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8081);
  print('🚀 Serveur Maalem lancé sur le port ${server.port}');

  await for (HttpRequest request in server) {
    request.response
      ..statusCode = HttpStatus.ok
      ..write('Bienvenue sur l\'API Maalem !')
      ..close();
  }
}