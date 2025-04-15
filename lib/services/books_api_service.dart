import 'package:http/http.dart' as http;
import 'dart:convert';

class BookApiService {
  // 📌 Fetch book details from Open Library API
  static Future<Map<String, dynamic>?> fetchBookDetails(String bookKey) async {
    if (bookKey.isEmpty) {
      print("❌ Error: Book Key is empty.");
      return null;
    }

    final url = Uri.parse("https://openlibrary.org/works/$bookKey.json");
    print("Fetching book details from: $url");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("❌ API Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Network Error: $e");
      return null;
    }
  }
}
