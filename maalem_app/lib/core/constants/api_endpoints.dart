// lib/core/constants/api_endpoints.dart

class ApiEndpoints {
  // En local avec un émulateur Android, localhost ne marche pas, on utilise 10.0.2.2.
  // Si tu testes sur un vrai téléphone ou Windows, on gardera localhost ou l'IP de ton PC.
  // Pour l'instant, mettons l'IP par défaut pour l'émulateur Android :
  // Change cette ligne :
  static const String baseUrl = 'http://localhost:8081/api';

  static const String bookings = '$baseUrl/bookings';
}
