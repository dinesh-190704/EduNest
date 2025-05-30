class Book {
  static const String _defaultImage = 'https://via.placeholder.com/150x200?text=No+Cover';
  final String id;
  final String title;
  final List<String> authors;
  final String description;
  String thumbnailUrl;
  final String? pdfUrl;
  final String publisher;
  final String publishedDate;
  final int? pageCount;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.thumbnailUrl,
    required this.pdfUrl,
    required this.publisher,
    required this.publishedDate,
    this.pageCount,
  }) {
    if (thumbnailUrl.isEmpty) {
      this.thumbnailUrl = _defaultImage;
    }
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>;
    final List<dynamic> authorsList = volumeInfo['authors'] ?? ['Unknown'];
    String? pdfUrl;

    // Try to get PDF download link
    if (volumeInfo['accessInfo']?['pdf']?['isAvailable'] == true) {
      pdfUrl = volumeInfo['accessInfo']?['pdf']?['downloadLink'];
    }

    // If no direct PDF, try to get preview link
    if (pdfUrl == null || pdfUrl.isEmpty) {
      pdfUrl = volumeInfo['previewLink'] ?? '';
    }

    return Book(
      id: json['id'] as String,
      title: volumeInfo['title'] as String,
      authors: authorsList.cast<String>(),
      description: volumeInfo['description'] ?? 'No description available',
      thumbnailUrl: volumeInfo['imageLinks']?['thumbnail'] ?? '',
      pdfUrl: pdfUrl,
      publisher: volumeInfo['publisher'] ?? 'Unknown',
      publishedDate: volumeInfo['publishedDate'] ?? 'Unknown',
      pageCount: volumeInfo['pageCount'] as int?,
    );
  }
}
