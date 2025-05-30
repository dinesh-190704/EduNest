import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:io';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _eventsCollection = 'events';

  EventService();

  // Create new event (Admin)
  Future<void> addEvent(Event event) async {
    try {
      // First upload image if exists
      if (event.imageUrl.isNotEmpty) {
        final ref = _storage.ref().child('events/${event.id}.jpg');
        await ref.getDownloadURL().catchError((error) async {
          print('Image does not exist yet, creating it...');
          return '';
        });
      }
      
      // Then save event data
      await _firestore
          .collection(_eventsCollection)
          .doc(event.id)
          .set(event.toJson());
    } catch (e) {
      print('Error creating event: $e');
      throw e;
    }
  }

  // Upload event image
  Future<String> uploadEventImage(String eventId, dynamic imageData) async {
    try {
      final ref = _storage.ref().child('events/$eventId.jpg');
      UploadTask uploadTask;

      if (imageData is File) {
        uploadTask = ref.putFile(imageData);
      } else if (imageData is Uint8List) {
        uploadTask = ref.putData(
          imageData,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        throw Exception('Invalid image data type');
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      throw e;
    }
  }

  // Get all events
  Stream<List<Event>> getEvents() {
    return _firestore
        .collection(_eventsCollection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Event.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  // Get event by ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final doc = await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .get();
      
      if (doc.exists) {
        return Event.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting event: $e');
      throw e;
    }
  }

  // Update event (Admin)
  Future<void> updateEvent(Event event) async {
    try {
      await _firestore
          .collection(_eventsCollection)
          .doc(event.id)
          .update(event.toJson());
    } catch (e) {
      print('Error updating event: $e');
      throw e;
    }
  }

  // Delete event (Admin)
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .delete();
    } catch (e) {
      print('Error deleting event: $e');
      throw e;
    }
  }
}
