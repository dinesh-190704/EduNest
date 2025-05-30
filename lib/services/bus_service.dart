import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/bus.dart';

class BusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _busCollection = 'buses';
  final String _routeCollection = 'routes';
  final String _driverCollection = 'drivers';

  // Bus Methods
  Stream<QuerySnapshot> getBuses() {
    return _firestore
        .collection(_busCollection)
        .orderBy('lastUpdated', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getBus(String busId) {
    return _firestore.collection(_busCollection).doc(busId).snapshots();
  }

  Future<void> addBus({
    required String busNumber,
    required String numberPlate,
    required String routeId,
    String? driverId,
    String? driverName,
    String? driverPhone,
    required LatLng startLocation,
    required LatLng endLocation,
  }) async {
    try {
      await _firestore.collection(_busCollection).add({
        'busNumber': busNumber,
        'numberPlate': numberPlate,
        'routeId': routeId,
        if (driverId != null) 'driverId': driverId,
        if (driverName != null) 'driverName': driverName,
        if (driverPhone != null) 'driverPhone': driverPhone,
        'isOnline': false,
        'startLocation': {
          'latitude': startLocation.latitude,
          'longitude': startLocation.longitude,
        },
        'endLocation': {
          'latitude': endLocation.latitude,
          'longitude': endLocation.longitude,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to add bus: $e',
      );
    }
  }

  Future<void> updateBusLocation(String busId, LatLng location) async {
    try {
      await _firestore.collection(_busCollection).doc(busId).update({
        'currentLocation': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to update bus location: $e',
      );
    }
  }

  Future<void> updateBusStatus(String busId, bool isOnline) async {
    try {
      await _firestore.collection(_busCollection).doc(busId).update({
        'isOnline': isOnline,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to update bus status: $e',
      );
    }
  }

  Future<void> updateBusDriver(
    String busId, {
    String? driverId,
    String? driverName,
    String? driverPhone,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (driverId != null) updateData['driverId'] = driverId;
      if (driverName != null) updateData['driverName'] = driverName;
      if (driverPhone != null) updateData['driverPhone'] = driverPhone;

      await _firestore.collection(_busCollection).doc(busId).update(updateData);
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to update bus driver: $e',
      );
    }
  }

  Future<void> deleteBus(String busId) async {
    try {
      await _firestore.collection(_busCollection).doc(busId).delete();
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to delete bus: $e',
      );
    }
  }

  // Route Methods
  Stream<QuerySnapshot> getRoutes() {
    return _firestore.collection(_routeCollection).snapshots();
  }

  Stream<DocumentSnapshot> getRoute(String routeId) {
    return _firestore.collection(_routeCollection).doc(routeId).snapshots();
  }

  Future<QuerySnapshot> getRoutesOnce() {
    return _firestore.collection(_routeCollection).get();
  }

  Future<void> addRoute({
    required String routeName,
    required List<Map<String, dynamic>> stops,
    String? driverId,
  }) async {
    try {
      await _firestore.collection(_routeCollection).add({
        'routeName': routeName,
        'stops': stops,
        if (driverId != null) 'driverId': driverId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to add route: $e';
    }
  }

  Future<void> updateRoute({
    required String routeId,
    String? routeName,
    List<Map<String, dynamic>>? stops,
    String? driverId,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (routeName != null) updates['routeName'] = routeName;
      if (stops != null) updates['stops'] = stops;
      if (driverId != null) updates['driverId'] = driverId;

      await _firestore.collection(_routeCollection).doc(routeId).update(updates);
    } catch (e) {
      throw 'Failed to update route: $e';
    }
  }

  Future<void> deleteRoute(String routeId) async {
    try {
      // Get all buses using this route
      final busesWithRoute = await _firestore
          .collection(_busCollection)
          .where('routeId', isEqualTo: routeId)
          .get();

      // Remove route ID from all buses using this route
      final batch = _firestore.batch();
      for (var busDoc in busesWithRoute.docs) {
        batch.update(busDoc.reference, {'routeId': null});
      }

      // Delete the route
      batch.delete(_firestore.collection(_routeCollection).doc(routeId));

      // Commit all changes
      await batch.commit();
    } catch (e) {
      throw 'Failed to delete route: $e';
    }
  }

  // Initialize predefined routes
  Future<void> initializePredefinedRoutes() async {
    final routes = [
      {
        'routeName': 'Thiruvallur to Jaya Engineering College',
        'stops': [
          {'name': 'Thiruvallur Bus Stand', 'latitude': 13.1407, 'longitude': 79.9087},
          {'name': 'Pattabiram', 'latitude': 13.1147, 'longitude': 80.0753},
          {'name': 'Avadi', 'latitude': 13.1067, 'longitude': 80.0972},
          {'name': 'Jaya Engineering College', 'latitude': 13.0827, 'longitude': 80.0437}
        ],
      },
      {
        'routeName': 'Avadi to Jaya Engineering College',
        'stops': [
          {'name': 'Avadi Bus Terminal', 'latitude': 13.1147, 'longitude': 80.0972},
          {'name': 'Pattabiram Military Siding', 'latitude': 13.1147, 'longitude': 80.0753},
          {'name': 'Jaya Engineering College', 'latitude': 13.0827, 'longitude': 80.0437}
        ],
      },
      {
        'routeName': 'Uthukottai to Jaya Engineering College',
        'stops': [
          {'name': 'Uthukottai', 'latitude': 13.3349, 'longitude': 79.9051},
          {'name': 'Thiruvallur', 'latitude': 13.1407, 'longitude': 79.9087},
          {'name': 'Pattabiram', 'latitude': 13.1147, 'longitude': 80.0753},
          {'name': 'Avadi', 'latitude': 13.1067, 'longitude': 80.0972},
          {'name': 'Jaya Engineering College', 'latitude': 13.0827, 'longitude': 80.0437}
        ],
      },
    ];

    for (final route in routes) {
      try {
        // Check if route already exists
        final existingRoutes = await _firestore
            .collection(_routeCollection)
            .where('routeName', isEqualTo: route['routeName'])
            .get();

        if (existingRoutes.docs.isEmpty) {
          await addRoute(
            routeName: route['routeName'] as String,
            stops: route['stops'] as List<Map<String, dynamic>>,
          );
        }
      } catch (e) {
        print('Failed to add route ${route['routeName']}: $e');
      }
    }
  }
}
