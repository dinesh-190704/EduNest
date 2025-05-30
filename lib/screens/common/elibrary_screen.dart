import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:google_fonts/google_fonts.dart';

class ELibraryScreen extends StatefulWidget {
  final String department;

  const ELibraryScreen({Key? key, this.department = 'All'}) : super(key: key);

  @override
  State<ELibraryScreen> createState() => _ELibraryScreenState();
}

class _ELibraryScreenState extends State<ELibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _books = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadRandomBooks(); // Load some books on start
  }

  Future<void> _loadRandomBooks() async {
    await _searchBooks('programming'); // fallback to a common term
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _books = [];
    });

    try {
      final response = await http.get(
        Uri.parse('https://openlibrary.org/search.json?q=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _books = data['docs'];
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load books.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _viewBookOnline(String key) async {
    final String url = "https://openlibrary.org$key";

    if (await url_launcher.canLaunchUrl(Uri.parse(url))) {
      await url_launcher.launchUrl(Uri.parse(url), mode: url_launcher.LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open book link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.department} Resources',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Books',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (_searchController.text.isEmpty) {
                      _loadRandomBooks();
                    } else {
                      _searchBooks(_searchController.text);
                    }
                  },
                ),
              ),
            ),
          ),
          if (_isLoading) const CupertinoActivityIndicator(),
          if (_errorMessage.isNotEmpty) Text(_errorMessage),
          Expanded(
            child: ListView.builder(
              itemCount: _books.length,
              itemBuilder: (context, index) {
                final book = _books[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    color: Colors.blue.shade50,
                    child: ListTile(
                      title: Text(
                        book['title'] ?? 'Unknown Title',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        book['author_name']?.join(', ') ?? 'Unknown Author',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          _viewBookOnline(book['key']);
                        },
                        child: const Text('View/Download'),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
