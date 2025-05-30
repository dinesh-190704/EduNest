import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemStatus { lost, found, resolved }
enum ItemCategory { wallet, electronics, stationery, idCards, other }

class LostFoundItem {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final ItemStatus status;
  final ItemCategory category;
  final String? imageUrl;
  final String userId;
  final bool anonymousContact;
  final String? contactInfo;
  final DateTime createdAt;
  final bool isResolved;

  LostFoundItem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.status,
    required this.category,
    this.imageUrl,
    required this.userId,
    this.anonymousContact = false,
    this.contactInfo,
    required this.createdAt,
    this.isResolved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'status': status.toString().split('.').last,
      'category': category.toString().split('.').last,
      'imageUrl': imageUrl,
      'userId': userId,
      'anonymousContact': anonymousContact,
      'contactInfo': contactInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'isResolved': isResolved,
    };
  }

  factory LostFoundItem.fromMap(Map<String, dynamic> map) {
    return LostFoundItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      location: map['location'] as String,
      date: (map['date'] as Timestamp).toDate(),
      status: ItemStatus.values.firstWhere(
          (e) => e.toString().split('.').last == map['status'],
          orElse: () => ItemStatus.lost),
      category: ItemCategory.values.firstWhere(
          (e) => e.toString().split('.').last == map['category'],
          orElse: () => ItemCategory.other),
      imageUrl: map['imageUrl'] as String?,
      userId: map['userId'] as String,
      anonymousContact: map['anonymousContact'] as bool? ?? false,
      contactInfo: map['contactInfo'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isResolved: map['isResolved'] as bool? ?? false,
    );
  }
}
