import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Bus {
  final String id;
  final String busNumber;
  final String numberPlate;
  final String routeId;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final bool isOnline;
  final LatLng startLocation;
  final LatLng endLocation;
  final DateTime? lastUpdated;
  final LatLng? currentLocation;

  Bus({
    required this.id,
    required this.busNumber,
    required this.numberPlate,
    required this.routeId,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.isOnline = false,
    required this.startLocation,
    required this.endLocation,
    this.lastUpdated,
    this.currentLocation,
  });

  factory Bus.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Document does not exist',
      );
    }

    final data = doc.data();
    if (data == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Document data is null',
      );
    }

    final busData = data as Map<String, dynamic>;
    
    // Validate required fields
    final missingFields = <String>[];
    if (busData['busNumber'] == null) missingFields.add('busNumber');
    if (busData['numberPlate'] == null) missingFields.add('numberPlate');
    if (busData['routeId'] == null) missingFields.add('routeId');
    if (busData['startLocation'] == null) missingFields.add('startLocation');
    if (busData['endLocation'] == null) missingFields.add('endLocation');

    if (missingFields.isNotEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Missing required bus fields: ${missingFields.join(', ')}',
      );
    }
    try {
      // Extract and validate location data
      final startLocationData = busData['startLocation'] as Map<String, dynamic>?;
      final endLocationData = busData['endLocation'] as Map<String, dynamic>?;
      final currentLocationData = busData['currentLocation'] as Map<String, dynamic>?;

      if (startLocationData == null || !startLocationData.containsKey('latitude') || !startLocationData.containsKey('longitude')) {
        throw FormatException('Invalid startLocation format');
      }
      if (endLocationData == null || !endLocationData.containsKey('latitude') || !endLocationData.containsKey('longitude')) {
        throw FormatException('Invalid endLocation format');
      }

      // Create LatLng objects
      final startLocation = LatLng(
        (startLocationData['latitude'] as num).toDouble(),
        (startLocationData['longitude'] as num).toDouble(),
      );
      final endLocation = LatLng(
        (endLocationData['latitude'] as num).toDouble(),
        (endLocationData['longitude'] as num).toDouble(),
      );
      final currentLocation = currentLocationData != null
          ? LatLng(
              (currentLocationData['latitude'] as num).toDouble(),
              (currentLocationData['longitude'] as num).toDouble(),
            )
          : null;

      return Bus(
        id: doc.id,
        busNumber: busData['busNumber'] as String,
        numberPlate: busData['numberPlate'] as String,
        routeId: busData['routeId'] as String,
        driverId: busData['driverId'] as String?,
        driverName: busData['driverName'] as String?,
        driverPhone: busData['driverPhone'] as String?,
        isOnline: busData['isOnline'] as bool? ?? false,
        startLocation: startLocation,
        endLocation: endLocation,
        lastUpdated: (busData['lastUpdated'] as Timestamp?)?.toDate(),
        currentLocation: currentLocation,
      );
    } catch (e) {
      print('Error parsing bus data: $e\nData: $busData');
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Error parsing bus data: $e',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'busNumber': busNumber,
      'numberPlate': numberPlate,
      'routeId': routeId,
      if (driverId != null) 'driverId': driverId,
      if (driverName != null) 'driverName': driverName,
      if (driverPhone != null) 'driverPhone': driverPhone,
      'isOnline': isOnline,
      'startLocation': {
        'latitude': startLocation.latitude,
        'longitude': startLocation.longitude,
      },
      'endLocation': {
        'latitude': endLocation.latitude,
        'longitude': endLocation.longitude,
      },
      if (currentLocation != null)
        'currentLocation': {
          'latitude': currentLocation!.latitude,
          'longitude': currentLocation!.longitude,
        },
      if (lastUpdated != null) 'lastUpdated': Timestamp.fromDate(lastUpdated!),
    };
  }

  Bus copyWith({
    String? id,
    String? busNumber,
    String? numberPlate,
    String? routeId,
    String? driverId,
    String? driverName,
    bool? isOnline,
    LatLng? startLocation,
    LatLng? endLocation,
    LatLng? currentLocation,
    DateTime? lastUpdated,
  }) {
    return Bus(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      numberPlate: numberPlate ?? this.numberPlate,
      routeId: routeId ?? this.routeId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      isOnline: isOnline ?? this.isOnline,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      currentLocation: currentLocation ?? this.currentLocation,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
