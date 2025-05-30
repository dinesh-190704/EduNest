import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user data
  Stream<UserModel?> getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      print('UserService: No authenticated user');
      return Stream.value(null);
    }

    print('UserService: Getting user data for ${user.uid}');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            print('UserService: No document found for user ${user.uid}');
            return null;
          }

          final data = doc.data()!;
          print('UserService: Got Firestore doc:');
          print('Department: ${data['department']}');
          print('Year: ${data['year']}');
          print('Section: ${data['section']}');
          print('StudentId: ${data['studentId']}');

          return UserModel.fromMap({
            ...data,
            'uid': user.uid, // Ensure uid is always set
          });
        });
  }

  // Update user profile image
  Future<String> updateProfileImage(dynamic image) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user for profile update');
        throw Exception('You must be logged in to update profile image');
      }
      print('Updating profile image for ${user.uid}');

      // Delete old profile image if it exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData['profileImageUrl'] != null) {
          try {
            await _storage.refFromURL(userData['profileImageUrl']).delete();
          } catch (e) {
            // Ignore error if old image doesn't exist
          }
        }
      }

      // Upload new image
      final ref = _storage.ref().child('profile_images/${user.uid}');
      if (kIsWeb) {
        if (image is Uint8List) {
          await ref.putData(image);
        } else {
          throw Exception('Invalid image format for web upload');
        }
      } else {
        if (image is File) {
          await ref.putFile(image);
        } else {
          throw Exception('Invalid image format for mobile upload');
        }
      }

      // Get download URL
      final imageUrl = await ref.getDownloadURL();
      print('Got image URL: $imageUrl');

      // Update user document
      await _firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': imageUrl,
      });
      print('Updated user document with new image URL');

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to update profile image: $e');
    }
  }

  // Update user profile data
  Future<void> updateUserProfile({
    String? name,
    String? department,
    String? year,
    String? section,
    String? studentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to update profile');
      }

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (department != null) updates['department'] = department;
      if (year != null) updates['year'] = year;
      if (section != null) updates['section'] = section;
      if (studentId != null) updates['studentId'] = studentId;

      print('UserService: Updating profile with:');
      print('Department: ${updates['department']}');
      print('Year: ${updates['year']}');
      print('Section: ${updates['section']}');
      print('StudentId: ${updates['studentId']}');

      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get user by registration number
  Future<UserModel?> getUserByRegNo(String regNo) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: regNo)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      return UserModel.fromMap({
        ...doc.data(),
        'uid': doc.id,
      });
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }
}
