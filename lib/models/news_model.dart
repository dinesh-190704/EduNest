class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final String source;
  final String publishedAt;
  final String author;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.source,
    required this.publishedAt,
    required this.author,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No description available',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'] ?? '',
      source: json['source']?['name'] ?? 'Unknown Source',
      publishedAt: json['publishedAt'] ?? '',
      author: json['author'] ?? 'Unknown Author',
    );
  }
}
