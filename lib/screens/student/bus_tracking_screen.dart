import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../services/bus_service.dart';
import '../../models/bus.dart';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  final _busService = BusService();
  final _mapController = MapController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Bus? _selectedBus;

  @override
  void initState() {
    super.initState();
    _initializeRoutes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeRoutes() async {
    try {
      // Initialize any required data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing routes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openInGoogleMaps(Bus bus) async {
    if (bus.currentLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bus location not available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final url =
        'https://www.google.com/maps/search/?api=1&query=${bus.currentLocation!.latitude},${bus.currentLocation!.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBusCard(Bus bus, {bool isSelected = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isSelected ? Colors.yellow[100] : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedBus = bus;
          });
          if (bus.currentLocation != null) {
            _mapController.move(bus.currentLocation!, 13);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus ${bus.busNumber}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Route ${bus.routeId}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.map),
                        onPressed: () => _openInGoogleMaps(bus),
                        tooltip: 'Open in Google Maps',
                      ),
                      if (bus.driverPhone != null)
                        IconButton(
                          icon: const Icon(Icons.phone),
                          onPressed: () async {
                            final url = 'tel:${bus.driverPhone}';
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url));
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not make phone call'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          tooltip: 'Call Driver',
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        bus.isOnline
                            ? Icons.circle
                            : Icons.circle_outlined,
                        color: bus.isOnline ? Colors.green : Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        bus.isOnline ? 'Online' : 'Offline',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  bus.isOnline ? Colors.green : Colors.red,
                            ),
                      ),
                    ],
                  ),
                  if (bus.lastUpdated != null)
                    Text(
                      'Updated ${timeago.format(bus.lastUpdated!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
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
        title: const Text('Bus Tracking'),
        backgroundColor: Colors.yellow[700],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Find and track your bus',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _busService.getBuses(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error loading buses',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final buses = snapshot.data?.docs
                    .map((doc) => Bus.fromFirestore(doc))
                    .where((bus) => bus != null)
                    .cast<Bus>()
                    .toList() ??
                    [];

                final filteredBuses = buses.where((bus) {
                  if (_searchQuery.isEmpty) return true;
                  return bus.busNumber.toLowerCase().contains(_searchQuery) ||
                      bus.routeId.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredBuses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.directions_bus_outlined,
                          color: Colors.grey,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No buses available',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.directions_bus),
                                const SizedBox(width: 8),
                                Text(
                                  'Available Routes (${filteredBuses.length})',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredBuses.length,
                              itemBuilder: (context, index) {
                                final bus = filteredBuses[index];
                                final isSelected = _selectedBus?.id == bus.id;
                                return _buildBusCard(bus, isSelected: isSelected);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: const LatLng(13.1067, 80.0722),
                          initialZoom: 11,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: [
                              for (final bus in filteredBuses)
                                if (bus.currentLocation != null)
                                  Marker(
                                    point: bus.currentLocation!,
                                    width: bus.id == _selectedBus?.id ? 50 : 40,
                                    height: bus.id == _selectedBus?.id ? 50 : 40,
                                    child: Stack(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: bus.isOnline
                                              ? Colors.green
                                              : Colors.red,
                                          size: bus.id == _selectedBus?.id ? 40 : 30,
                                        ),
                                        if (!bus.isOnline)
                                          const Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Icon(
                                              Icons.offline_bolt,
                                              color: Colors.red,
                                              size: 12,
                                            ),
                                          ),
                                      ],
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
          ),
        ],
      ),
    );
  }
}
