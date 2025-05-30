class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final String locationUrl; // Google Maps or venue location URL
  final String registrationUrl; // Registration form or website URL
  final DateTime date;
  final String imageUrl;
  final String status; // 'Now', 'Upcoming', etc.

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    this.locationUrl = '',
    this.registrationUrl = '',
    this.imageUrl = '',
    this.status = 'Upcoming',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'locationUrl': locationUrl,
      'registrationUrl': registrationUrl,
      'date': date.toIso8601String(),
      'imageUrl': imageUrl,
      'status': status,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      locationUrl: json['locationUrl'] ?? '',
      registrationUrl: json['registrationUrl'] ?? '',
      date: DateTime.parse(json['date']),
      imageUrl: json['imageUrl'] ?? '',
      status: json['status'] ?? 'Upcoming',
    );
  }
}
