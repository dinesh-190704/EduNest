import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';

class NewsService {
  static const String _baseUrl = 'https://gnews.io/api/v4';
  static const String _apiKey = '72690f629d92040a17e54a6edac51679';

  Future<List<NewsArticle>> getTechNews() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/top-headlines?category=technology&lang=en&apikey=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;
        return articles.map((article) => NewsArticle(
          title: article['title'] ?? 'No Title',
          description: article['description'] ?? 'Click to read more',
          url: article['url'] ?? '',
          imageUrl: article['image'] ?? '',
          source: article['source']?['name'] ?? 'Unknown Source',
          publishedAt: article['publishedAt'] ?? '',
          author: article['author'] ?? 'Unknown',
        )).toList();
      } else {
        throw Exception('Failed to fetch tech news: ${response.statusCode}');
      }

      return [];
    } catch (e) {
      throw Exception('Error fetching tech news: $e');
    }
  }
}
