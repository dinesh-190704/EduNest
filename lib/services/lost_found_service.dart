import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/lost_found_item.dart';

class LostFoundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'lost_found_items';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new lost/found item
  Future<String> createItem(LostFoundItem item, dynamic image) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to create an item');
      }

      String? imageUrl;
      if (image != null) {
        final ref = _storage.ref().child('lost_found/${item.id}');
        if (kIsWeb) {
          // Handle web upload
          if (image is Uint8List) {
            await ref.putData(image);
          } else {
            throw Exception('Invalid image format for web upload');
          }
        } else {
          // Handle mobile upload
          if (image is File) {
            await ref.putFile(image);
          } else {
            throw Exception('Invalid image format for mobile upload');
          }
        }
        imageUrl = await ref.getDownloadURL();
      }

      final itemWithImage = LostFoundItem(
        id: item.id,
        title: item.title,
        description: item.description,
        location: item.location,
        date: item.date,
        status: item.status,
        category: item.category,
        imageUrl: imageUrl,
        userId: currentUser.uid, // Use current user's ID
        anonymousContact: item.anonymousContact,
        contactInfo: item.contactInfo,
        createdAt: DateTime.now(),
        isResolved: false,
      );

      await _firestore
          .collection(_collection)
          .doc(item.id)
          .set(itemWithImage.toMap());
      return item.id;
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  // Get all items with optional filters
  Stream<List<LostFoundItem>> getItems({
    ItemStatus? status,
    ItemCategory? category,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    Query query = _firestore.collection(_collection);

    if (status != null) {
      query = query.where('status', isEqualTo: status.toString());
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category.toString());
    }
    if (startDate != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query =
          query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => LostFoundItem.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        return items.where((item) {
          final searchLower = searchQuery.toLowerCase();
          return item.title.toLowerCase().contains(searchLower) ||
              item.description.toLowerCase().contains(searchLower) ||
              item.location.toLowerCase().contains(searchLower);
        }).toList();
      }

      return items;
    });
  }

  // Update item status
  Future<void> updateItemStatus(String itemId, ItemStatus newStatus) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(itemId)
          .update({'status': newStatus.toString()});
    } catch (e) {
      throw Exception('Failed to update item status: $e');
    }
  }

  // Mark item as resolved
  Future<void> markAsResolved(String itemId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(itemId)
          .update({'isResolved': true});
    } catch (e) {
      throw Exception('Failed to mark item as resolved: $e');
    }
  }

  // Check if user can delete item
  Future<bool> canDeleteItem(String itemId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get user role
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final userRole = userData['role'] as String;

      // Get item
      final itemDoc = await _firestore.collection(_collection).doc(itemId).get();
      if (!itemDoc.exists) return false;
      
      final itemData = itemDoc.data() as Map<String, dynamic>;

      // Admin can delete any item
      if (userRole == 'admin') return true;

      // Students can only delete their own items
      return itemData['userId'] == currentUser.uid;
    } catch (e) {
      return false;
    }
  }

  // Delete item
  Future<void> deleteItem(String itemId) async {
    try {
      final canDelete = await canDeleteItem(itemId);
      if (!canDelete) {
        throw Exception('You do not have permission to delete this item');
      }

      final item = await _firestore.collection(_collection).doc(itemId).get();
      final data = item.data();
      if (data != null && data['imageUrl'] != null) {
        await _storage.refFromURL(data['imageUrl']).delete();
      }
      await _firestore.collection(_collection).doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }
}
