import 'package:http/http.dart' as http;

class ApiClient {
  // IMPORTANT: 10.0.2.2 est l'adresse de localhost pour l'émulateur Android
  // Si tu testes sur un vrai téléphone, utilise l'adresse IP de ton PC (ex: 192.168.1.15)
  // Pour Chrome (Web) :
  static const String baseUrl = "http://localhost:8081"; 
  //static const String baseUrl = "http://10.0.2.2:8081";

  // Méthode pour ajouter le token JWT aux headers si besoin
  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }
}