import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class BusStop {
  final String name;
  final LatLng location;
  final String? description;
  final DateTime? estimatedArrival;

  BusStop({
    required this.name,
    required this.location,
    this.description,
    this.estimatedArrival,
  });

  factory BusStop.fromMap(Map<String, dynamic> map) {
    return BusStop(
      name: map['name'] ?? '',
      location: LatLng(
        map['location']['latitude'] ?? 0.0,
        map['location']['longitude'] ?? 0.0,
      ),
      description: map['description'],
      estimatedArrival: (map['estimatedArrival'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      if (description != null) 'description': description,
      if (estimatedArrival != null)
        'estimatedArrival': Timestamp.fromDate(estimatedArrival!),
    };
  }
}

class BusRoute {
  final String id;
  final String routeName;
  final String? driverId;
  final List<BusStop> stops;
  final bool isActive;
  final DateTime? lastUpdated;

  BusRoute({
    required this.id,
    required this.routeName,
    this.driverId,
    required this.stops,
    this.isActive = true,
    this.lastUpdated,
  });

  factory BusRoute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusRoute(
      id: doc.id,
      routeName: data['routeName'] ?? '',
      driverId: data['driverId'],
      stops: (data['stops'] as List?)
          ?.map((stop) => BusStop.fromMap(stop))
          .toList() ?? [],
      isActive: data['isActive'] ?? true,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeName': routeName,
      if (driverId != null) 'driverId': driverId,
      'stops': stops.map((stop) => stop.toMap()).toList(),
      'isActive': isActive,
      if (lastUpdated != null) 'lastUpdated': Timestamp.fromDate(lastUpdated!),
    };
  }

  BusRoute copyWith({
    String? id,
    String? routeName,
    String? driverId,
    List<BusStop>? stops,
    bool? isActive,
    DateTime? lastUpdated,
  }) {
    return BusRoute(
      id: id ?? this.id,
      routeName: routeName ?? this.routeName,
      driverId: driverId ?? this.driverId,
      stops: stops ?? this.stops,
      isActive: isActive ?? this.isActive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
