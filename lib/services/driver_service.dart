import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/driver_model.dart';

class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _driverCollection = 'drivers';

  // Add a new driver
  Future<void> addDriver({
    required String name,
    required String phoneNumber,
    String? licenseNumber,
    String? profileImage,
  }) async {
    try {
      await _firestore.collection(_driverCollection).add({
        'name': name,
        'phoneNumber': phoneNumber,
        if (licenseNumber != null) 'licenseNumber': licenseNumber,
        if (profileImage != null) 'profileImage': profileImage,
        'isOnline': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to add driver: $e';
    }
  }

  // Update driver profile
  Future<void> updateDriver({
    required String driverId,
    String? name,
    String? phoneNumber,
    String? licenseNumber,
    String? profileImage,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (licenseNumber != null) updates['licenseNumber'] = licenseNumber;
      if (profileImage != null) updates['profileImage'] = profileImage;
      updates['lastUpdated'] = FieldValue.serverTimestamp();

      await _firestore.collection(_driverCollection).doc(driverId).update(updates);
    } catch (e) {
      throw 'Failed to update driver: $e';
    }
  }

  // Start location tracking
  Stream<Position>? startLocationTracking({
    required String driverId,
    required Function(String) onError,
  }) async* {
    try {
      // Request location permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          onError('Location permission denied');
          return;
        }
      }

      // Set driver as online
      await _firestore.collection(_driverCollection).doc(driverId).update({
        'isOnline': true,
      });

      // Start location tracking
      yield* Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).map((position) {
        // Update driver location in Firestore
        _firestore.collection(_driverCollection).doc(driverId).update({
          'currentLocation': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        return position;
      });
    } catch (e) {
      onError('Error tracking location: $e');
      rethrow;
    }
  }

  // Stop location tracking
  Future<void> stopLocationTracking(String driverId) async {
    try {
      await _firestore.collection(_driverCollection).doc(driverId).update({
        'isOnline': false,
      });
    } catch (e) {
      throw 'Failed to stop tracking: $e';
    }
  }

  // Get all drivers
  Stream<List<Driver>> getDrivers() {
    return _firestore
        .collection(_driverCollection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Driver.fromFirestore(doc))
            .toList());
  }

  // Get specific driver
  Stream<Driver?> getDriver(String driverId) {
    return _firestore
        .collection(_driverCollection)
        .doc(driverId)
        .snapshots()
        .map((doc) => doc.exists ? Driver.fromFirestore(doc) : null);
  }

  // Get driver by route
  Stream<Driver?> getDriverByRoute(String routeId) {
    return _firestore
        .collection(_driverCollection)
        .where('assignedRouteId', isEqualTo: routeId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty
            ? Driver.fromFirestore(snapshot.docs.first)
            : null);
  }

  // Delete driver
  Future<void> deleteDriver(String driverId) async {
    try {
      await _firestore.collection(_driverCollection).doc(driverId).delete();
    } catch (e) {
      throw 'Failed to delete driver: $e';
    }
  }
}
