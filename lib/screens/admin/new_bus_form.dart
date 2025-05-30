import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../services/bus_service.dart';
import '../../models/bus.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewBusForm extends StatefulWidget {
  const NewBusForm({super.key});

  @override
  State<NewBusForm> createState() => _NewBusFormState();
}

class _NewBusFormState extends State<NewBusForm> {
  late MapController _mapController;
  LatLng? _startLocation;
  LatLng? _endLocation;
  bool _selectingStart = true; // true for start location, false for end location
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await LocationPermissionHandler.getCurrentLocation();
    if (position != null) {
      setState(() {
        _startLocation = LatLng(position.latitude, position.longitude);
        _startLatController.text = position.latitude.toString();
        _startLngController.text = position.longitude.toString();
        _mapController.move(_startLocation!, 13);
      });
    } else {
      // Default to a location in India if permission denied
      setState(() {
        _startLocation = LatLng(20.5937, 78.9629);
        _mapController.move(_startLocation!, 5);
      });
    }

  }
  final _formKey = GlobalKey<FormState>();
  final _busService = BusService();

  final _busNumberController = TextEditingController();
  final _numberPlateController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _routeIdController = TextEditingController();
  final _startLatController = TextEditingController();
  final _startLngController = TextEditingController();
  final _endLatController = TextEditingController();
  final _endLngController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _busNumberController.dispose();
    _numberPlateController.dispose();
    _routeIdController.dispose();
    _startLatController.dispose();
    _startLngController.dispose();
    _endLatController.dispose();
    _endLngController.dispose();
    super.dispose();
  }

  Future<void> _saveBus() async {
    if (_startLocation == null || _endLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end locations')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _busService.addBus(
        busNumber: _busNumberController.text,
        numberPlate: _numberPlateController.text,
        routeId: _routeIdController.text,
        driverName: _driverNameController.text.isNotEmpty
          ? _driverNameController.text
          : null,
        driverPhone: _driverPhoneController.text.isNotEmpty
          ? _driverPhoneController.text
          : null,
        startLocation: LatLng(
          double.parse(_startLatController.text),
          double.parse(_startLngController.text),
        ),
        endLocation: LatLng(
          double.parse(_endLatController.text),
          double.parse(_endLngController.text),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Bus'),
        backgroundColor: Colors.yellow[700],
      ),
      body: Column(
        children: [
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(20.5937, 78.9629),
              initialZoom: 5,
              onTap: (tapPosition, point) {
                setState(() {
                  if (_selectingStart) {
                    _startLocation = point;
                    _startLatController.text = point.latitude.toString();
                    _startLngController.text = point.longitude.toString();
                  } else {
                    _endLocation = point;
                    _endLatController.text = point.latitude.toString();
                    _endLngController.text = point.longitude.toString();
                  }
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  if (_startLocation != null)
                    Marker(
                      point: _startLocation!,
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  if (_endLocation != null)
                    Marker(
                      point: _endLocation!,
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectingStart = true),
                icon: Icon(Icons.add_location),
                label: Text('Set Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectingStart ? Colors.green : Colors.grey,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectingStart = false),
                icon: Icon(Icons.add_location),
                label: Text('Set End'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_selectingStart ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _busNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Bus Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _numberPlateController,
                        decoration: const InputDecoration(
                          labelText: 'Number Plate',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _driverNameController,
                        decoration: const InputDecoration(
                          labelText: 'Driver Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _driverPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Driver Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance.collection('routes').get(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final routes = snapshot.data?.docs ?? [];
                          
                          return DropdownButtonFormField<String>(
                            value: _routeIdController.text.isEmpty ? null : _routeIdController.text,
                            decoration: const InputDecoration(
                              labelText: 'Select Route',
                              border: OutlineInputBorder(),
                              hintText: 'Select a route',
                            ),
                            items: routes.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text('${data['routeName'] ?? 'Unnamed Route'} (${doc.id})'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _routeIdController.text = value;
                                });
                              }
                            },
                            validator: (value) => value == null ? 'Please select a route' : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Start Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startLatController,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Required'
                                  : double.tryParse(value!) == null
                                      ? 'Invalid number'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _startLngController,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Required'
                                  : double.tryParse(value!) == null
                                      ? 'Invalid number'
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'End Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _endLatController,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Required'
                                  : double.tryParse(value!) == null
                                      ? 'Invalid number'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _endLngController,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Required'
                                  : double.tryParse(value!) == null
                                      ? 'Invalid number'
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveBus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Save Bus',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
              ),
                ],
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }
}
