import 'package:maalem_app/data/services/api_client.dart';

class ApiEndpoints {
  static String get baseUrl => '${ApiClient.baseUrl}/api';

  static String get bookings => '$baseUrl/bookings';

  static String get socketUrl => ApiClient.baseUrl;

  static String get messages => '$baseUrl/messages';
}
