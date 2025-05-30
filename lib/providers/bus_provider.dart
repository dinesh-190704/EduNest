import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/bus.dart';
import '../services/bus_service.dart';

class BusProvider extends ChangeNotifier {
  final BusService _busService = BusService();
  List<Bus> _buses = [];
  bool _isLoading = false;
  String? _error;

  List<Bus> get buses => _buses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBuses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance.collection('buses').get();
      _buses = snapshot.docs.map((doc) => Bus.fromFirestore(doc)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<Bus>> get busesStream {
    return _busService.getBuses().map(
          (snapshot) => snapshot.docs
              .map((doc) => Bus.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addBus({
    required String busNumber,
    required String numberPlate,
    required String routeId,
    required LatLng startLocation,
    required LatLng endLocation,
  }) async {
    try {
      await _busService.addBus(
        busNumber: busNumber,
        numberPlate: numberPlate,
        routeId: routeId,
        startLocation: startLocation,
        endLocation: endLocation,
      );
      await loadBuses();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> updateBusLocation(String busId, LatLng location) async {
    try {
      await _busService.updateBusLocation(busId, location);
      await loadBuses();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> deleteBus(String busId) async {
    try {
      await _busService.deleteBus(busId);
      await loadBuses();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }
}
