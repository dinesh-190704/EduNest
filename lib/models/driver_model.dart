import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Driver {
  final String id;
  final String name;
  final String phoneNumber;
  final String? assignedRouteId;
  final bool isOnline;
  final LatLng? currentLocation;
  final DateTime? lastUpdated;
  final String? licenseNumber;
  final String? profileImage;

  Driver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.assignedRouteId,
    this.isOnline = false,
    this.currentLocation,
    this.lastUpdated,
    this.licenseNumber,
    this.profileImage,
  });

  factory Driver.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Driver(
      id: doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      assignedRouteId: data['assignedRouteId'],
      isOnline: data['isOnline'] ?? false,
      currentLocation: data['currentLocation'] != null
          ? LatLng(
              data['currentLocation']['latitude'],
              data['currentLocation']['longitude'],
            )
          : null,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
      licenseNumber: data['licenseNumber'],
      profileImage: data['profileImage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      if (assignedRouteId != null) 'assignedRouteId': assignedRouteId,
      'isOnline': isOnline,
      if (currentLocation != null)
        'currentLocation': {
          'latitude': currentLocation!.latitude,
          'longitude': currentLocation!.longitude,
        },
      if (lastUpdated != null) 'lastUpdated': Timestamp.fromDate(lastUpdated!),
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (profileImage != null) 'profileImage': profileImage,
    };
  }

  Driver copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? assignedRouteId,
    bool? isOnline,
    LatLng? currentLocation,
    DateTime? lastUpdated,
    String? licenseNumber,
    String? profileImage,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      assignedRouteId: assignedRouteId ?? this.assignedRouteId,
      isOnline: isOnline ?? this.isOnline,
      currentLocation: currentLocation ?? this.currentLocation,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
