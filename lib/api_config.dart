import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiConfig {
  // URL Vercel API — api4
  static const String musicApiBaseUrl =
      "https://api4-git-main-yusrilwibus-projects.vercel.app";

  // Cek apakah API aktif
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$musicApiBaseUrl/api/search?query=test'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
