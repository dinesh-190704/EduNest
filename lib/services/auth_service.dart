import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  UserModel? _userFromFirebase(User? user) {
    return user != null ? UserModel(
      uid: user.uid,
      email: user.email!,
      role: '',
      name: '',
      department: '',
      profileImageUrl: '',
      studentId: '',
      staffId: '',
      year: '',
    ) : null;
  }

  // Sign in with email and password
  Future<(UserModel?, String?)> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Get user role from Firestore
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return (UserModel(
            uid: user.uid,
            email: user.email!,
            role: data['role'] ?? 'student',
            name: data['name'] ?? '',
            department: data['department'] ?? '',
            profileImageUrl: data['profileImageUrl'],
            studentId: data['studentId'] ?? '',
            staffId: data['staffId'] ?? '',
            year: data['year'] ?? '',
          ), null);
        }
      }
      return (null, 'User data not found');
    } catch (e) {
      return (null, e.toString());
    }
  }

  // Register with email and password
  Future<(UserModel?, String?)> registerWithEmailAndPassword(
      String email,
      String password,
      String role,
      {required String name,
      required String department,
      String? profileImageUrl,
      String? studentId,
      String? staffId,
      String? year}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Create a new document for the user with the uid
        final userData = {
          'uid': user.uid,
          'email': email,
          'role': role,
          'name': name,
          'department': department,
          'profileImageUrl': profileImageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (role == 'student') {
          userData['studentId'] = studentId;
          userData['year'] = year;
        } else {
          userData['staffId'] = staffId;
        }

        await _firestore.collection('users').doc(user.uid).set(userData);

        return (UserModel(
          uid: user.uid,
          email: user.email!,
          role: role,
          name: name,
          department: department,
          profileImageUrl: profileImageUrl,
          studentId: studentId ?? '',
          staffId: staffId ?? '',
          year: year ?? '',
        ), null);
      }
      return (null, 'User data not found');
    } catch (e) {
      return (null, e.toString());
    }
  }

  // Reset password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Sign out
  Future<String?> signOut() async {
    try {
      await _auth.signOut();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
