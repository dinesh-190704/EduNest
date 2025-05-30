import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book_model.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class BookService {
  static const String _archiveUrl = 'https://archive.org/advancedsearch.php';
  static const String _archiveDetailsUrl = 'https://archive.org/details/';
  final Dio _dio = Dio();

  Future<void> launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<List<Book>> searchBooks(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_archiveUrl?q=$query AND mediatype:(texts) AND format:(pdf)&fl[]=identifier,title,creator,description,publicdate&sort[]=downloads desc&output=json&rows=20',
        ),
      );

      if (response.statusCode != 200) {
        throw 'Failed to search books: ${response.statusCode}';
      }

      final data = json.decode(response.body);
      if (data['response'] == null || data['response']['docs'] == null) {
        return [];
      }

      final docs = data['response']['docs'] as List;
      return docs.map((doc) {
          final id = doc['identifier'] as String;
          final title = doc['title'] as String? ?? 'Unknown Title';
          final authors = (doc['creator'] as List?)?.cast<String>() ?? ['Unknown Author'];
          final description = doc['description'] as String? ?? 'No description available';
          final publishedDate = doc['publicdate'] as String? ?? 'Unknown Date';
          final pdfUrl = '$_archiveDetailsUrl$id/page/1/mode/1up';
          
          return Book(
            id: id,
            title: title,
            authors: authors,
            description: description,
            thumbnailUrl: '$_archiveDetailsUrl$id/page/1/mode/1up',
            pdfUrl: pdfUrl,
            publisher: 'Internet Archive',
            publishedDate: publishedDate,
            pageCount: null,
          );
        }).toList();
    } catch (e) {
      print('Error searching books: $e');
      return [];
    }
  }

  Future<String> downloadBook(String url, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            print('Download progress: ${(progress * 100).toStringAsFixed(0)}%');
          }
        },
      );

      return filePath;
    } catch (e) {
      print('Error downloading book: $e');
      throw 'Failed to download book: $e';
    }
  }
}
