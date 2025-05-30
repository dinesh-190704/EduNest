import 'package:flutter/material.dart';
import '../../services/bus_service.dart';

class NewRouteForm extends StatefulWidget {
  const NewRouteForm({super.key});

  @override
  State<NewRouteForm> createState() => _NewRouteFormState();
}

class _NewRouteFormState extends State<NewRouteForm> {
  final _formKey = GlobalKey<FormState>();
  final _busService = BusService();
  final _routeNameController = TextEditingController();
  final List<TextEditingController> _stopControllers = [];

  @override
  void dispose() {
    _routeNameController.dispose();
    for (var controller in _stopControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addStop() {
    setState(() {
      _stopControllers.add(TextEditingController());
    });
  }

  void _removeStop(int index) {
    setState(() {
      _stopControllers[index].dispose();
      _stopControllers.removeAt(index);
    });
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final stops = _stopControllers
          .map((controller) => {'name': controller.text.trim()})
          .toList();

      await _busService.addRoute(
        routeName: _routeNameController.text.trim(),
        stops: stops,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding route: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Route'),
        backgroundColor: Colors.yellow[700],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _routeNameController,
                        decoration: const InputDecoration(
                          labelText: 'Route Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Stops',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addStop,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Stop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _stopControllers.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _stopControllers[index],
                                    decoration: InputDecoration(
                                      labelText: 'Stop ${index + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                    validator: (value) =>
                                        value?.isEmpty ?? true ? 'Required' : null,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle),
                                  color: Colors.red,
                                  onPressed: () => _removeStop(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (_stopControllers.isEmpty)
                        const Center(
                          child: Text(
                            'Add stops using the button above',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save Route',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
