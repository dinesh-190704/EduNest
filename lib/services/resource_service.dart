import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/resource_model.dart';
import '../utils/file_interface.dart';

class ResourceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = Uuid();
  
  // Collection references
  CollectionReference get _resources => _firestore.collection('resources');

  Stream<List<Resource>> getResources(String category) {
    return _resources
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Resource.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addResource(Resource resource) async {
    await _resources.doc(resource.id).set(resource.toJson());
  }

  Future<String> uploadFile(PlatformFile file, String category) async {
    final String fileName = '${_uuid.v4()}_${file.name}';
    final ref = _storage.ref().child('$category/$fileName');

    try {
      if (kIsWeb) {
        // Web platform
        if (file.bytes != null) {
          await ref.putData(
            file.bytes!,
            SettableMetadata(contentType: 'application/octet-stream'),
          );
        } else {
          throw Exception('File bytes are null');
        }
      } else {
        // Mobile/Desktop platform
        final filePath = file.path;
        if (filePath != null) {
          final fileObj = File(filePath);
          await ref.putFile(
            fileObj,
            SettableMetadata(contentType: 'application/octet-stream'),
          );
        } else {
          throw Exception('File path is null');
        }
      }
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Failed to upload file');
    }
  }

  Future<void> downloadFile(String url, String fileName) async {
    try {
      await downloadFileFromUrl(url, fileName);
    } catch (e) {
      print('Error downloading file: $e');
      throw Exception('Failed to download file');
    }
  }

  Future<void> deleteResource(String id, String fileUrl) async {
    try {
      // Delete from Firestore
      await _resources.doc(id).delete();
      
      // Delete from Storage if URL exists
      if (fileUrl.isNotEmpty) {
        await _storage.refFromURL(fileUrl).delete();
      }
    } catch (e) {
      print('Error deleting resource: $e');
      throw Exception('Failed to delete resource');
    }
  }
}
