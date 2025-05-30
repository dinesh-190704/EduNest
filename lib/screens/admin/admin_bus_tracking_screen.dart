import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/bus_service.dart';
import '../../models/bus.dart';
import '../../utils/map_api_key.dart';
import 'new_bus_form.dart';
import 'new_route_form.dart';
import 'route_management_screen.dart';

class AdminBusTrackingScreen extends StatefulWidget {
  const AdminBusTrackingScreen({super.key});

  @override
  State<AdminBusTrackingScreen> createState() => _AdminBusTrackingScreenState();
}

class _AdminBusTrackingScreenState extends State<AdminBusTrackingScreen> {
  final _busService = BusService();
  final _mapController = MapController();
  Bus? _selectedBus;
  List<LatLng> _routePoints = [];

  Future<void> _openInGoogleMaps(Bus bus) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${bus.startLocation.latitude},${bus.startLocation.longitude}&destination=${bus.endLocation.latitude},${bus.endLocation.longitude}&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<List<LatLng>> _getRoutePoints(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${start.latitude},${start.longitude}'
        '&destination=${end.latitude},${end.longitude}'
        '&mode=driving'
        '&alternatives=false'
        '&key=$googleMapsApiKey'
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final List<LatLng> points = [];

          // Add start location
          points.add(LatLng(leg['start_location']['lat'], leg['start_location']['lng']));

          // Add points from each step
          for (final step in leg['steps']) {
            final List<LatLng> stepPoints = _decodePolyline(step['polyline']['points']);
            points.addAll(stepPoints);
          }

          // Add end location
          points.add(LatLng(leg['end_location']['lat'], leg['end_location']['lng']));

          return points;
        }
      }
    } catch (e) {
      print('Error getting route points: $e');
      return [start, end];
    }
    return [start, end];
  }

  Widget _buildBusCard({
    required Bus bus,
    required bool isSelected,
    required List<String> stops,
    String? error,
  }) {
    return Card(
      elevation: isSelected ? 8 : 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Colors.yellow[700]!, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          setState(() => _selectedBus = bus);
          if (bus.currentLocation != null) {
            _mapController.move(
              bus.currentLocation!,
              15,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bus ${bus.busNumber}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bus.numberPlate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (bus.driverName != null || bus.driverPhone != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${bus.driverName ?? 'No name'} ${bus.driverPhone != null ? '• ${bus.driverPhone}' : ''}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.directions_bus,
                    size: 40,
                    color: Colors.yellow[700],
                  ),
                ],
              ),
              const Divider(height: 24),
              if (error != null)
                Text(
                  error,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                  ),
                )
              else ...[
                const Text(
                  'Stops:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: stops
                      .map((stop) => Chip(
                            label: Text(stop.trim()),
                            backgroundColor: Colors.grey[200],
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Bus Tracking'),
        backgroundColor: Colors.yellow[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RouteManagementScreen(),
                ),
              );
            },
            tooltip: 'Manage Routes',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _busService.getBuses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No bus data available'));
          }

          final buses = snapshot.data!.docs
              .where((doc) => doc.data() != null)
              .map((doc) {
                try {
                  return Bus.fromFirestore(doc);
                } catch (e) {
                  print('Error parsing bus data: $e');
                  return null;
                }
              })
              .where((bus) => bus != null)
              .cast<Bus>()
              .toList();

          if (buses.isEmpty) {
            return const Center(child: Text('No buses available'));
          }

          return Row(
            children: [
              Expanded(
                flex: 1,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: buses.length,
                  itemBuilder: (context, index) {
                    final bus = buses[index];
                    final isSelected = _selectedBus?.id == bus.id;

                    if (bus.routeId.isEmpty) {
                      return _buildBusCard(
                        bus: bus,
                        isSelected: isSelected,
                        stops: const [],
                        error: 'No route assigned',
                      );
                    }

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('routes')
                          .doc(bus.routeId)
                          .get(),
                      builder: (context, routeSnapshot) {
                        if (routeSnapshot.connectionState == ConnectionState.waiting) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }

                        if (routeSnapshot.hasError) {
                          return _buildBusCard(
                            bus: bus,
                            isSelected: isSelected,
                            stops: const [],
                            error: 'Error loading route',
                          );
                        }

                        if (!routeSnapshot.hasData || !routeSnapshot.data!.exists) {
                          return _buildBusCard(
                            bus: bus,
                            isSelected: isSelected,
                            stops: const [],
                            error: 'Route not found',
                          );
                        }

                        final routeData = routeSnapshot.data!.data() as Map<String, dynamic>?;
                        final stops = (routeData?['stops'] as List<dynamic>?)?.cast<String>() ?? [];

                        return _buildBusCard(
                          bus: bus,
                          isSelected: isSelected,
                          stops: stops,
                          error: null,
                        );
                      },
                    );
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(20.5937, 78.9629),
                    initialZoom: 5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    if (_selectedBus != null && _selectedBus!.currentLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedBus!.currentLocation!,
                            child: Icon(
                              Icons.directions_bus,
                              color: Colors.yellow[700],
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
