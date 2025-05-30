import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/news_model.dart';
import '../../services/news_service.dart';

class TechNewsScreen extends StatefulWidget {
  const TechNewsScreen({super.key});

  @override
  State<TechNewsScreen> createState() => _TechNewsScreenState();
}

class _TechNewsScreenState extends State<TechNewsScreen> {
  final _newsService = NewsService();
  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      final articles = await _newsService.getTechNews();
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openArticle(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open article',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tech News',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadNews();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading news',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.red[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadNews,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          'Try Again',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNews,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _articles.length,
                    itemBuilder: (context, index) {
                      final article = _articles[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _openArticle(article.url),
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (article.imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    article.imageUrl,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            article.source,
                                            style: GoogleFonts.poppins(
                                              color: Colors.blue[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          article.publishedAt,
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      article.title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      article.description,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Text(
                                          'By ${article.author}',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: () =>
                                              _openArticle(article.url),
                                          icon: const Icon(Icons.arrow_forward),
                                          label: Text(
                                            'Read More',
                                            style: GoogleFonts.poppins(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
