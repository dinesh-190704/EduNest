import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class EventUploadScreen extends StatefulWidget {
  const EventUploadScreen({Key? key}) : super(key: key);

  @override
  State<EventUploadScreen> createState() => _EventUploadScreenState();
}

class _EventUploadScreenState extends State<EventUploadScreen> {
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        // Handle web image
        final bytes = await image.readAsBytes();
        setState(() {
          _webImage = bytes;
          _selectedImage = bytes;
          _imageName = image.name;
        });
      } else {
        // Handle mobile image
        setState(() {
          _selectedImage = File(image.path);
          _imageName = image.name;
        });
      }
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationUrlController = TextEditingController();
  final _registrationUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  dynamic _selectedImage;
  Uint8List? _webImage;
  String? _imageName;
  DateTime _selectedDate = DateTime.now();
  late EventService _eventService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _eventService = EventService();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _locationUrlController.dispose();
    _registrationUrlController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _uploadEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String eventId = const Uuid().v4();
      String imageUrl = '';
      
      if (_selectedImage != null) {
        // Upload image first
        if (kIsWeb) {
          imageUrl = await _eventService.uploadEventImage(eventId, _webImage!);
        } else {
          imageUrl = await _eventService.uploadEventImage(eventId, _selectedImage as File);
        }
      }

      final event = Event(
        id: eventId,
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        locationUrl: _locationUrlController.text,
        registrationUrl: _registrationUrlController.text,
        date: _selectedDate,
        imageUrl: imageUrl,
        status: _selectedDate.isAtSameMomentAs(DateTime.now()) ? 'Now' : 'Upcoming',
      );

      await _eventService.addEvent(event);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating event: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: Text(
          'Create Event',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[900]!],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Event Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter event title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter event description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter event location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationUrlController,
                      decoration: InputDecoration(
                        labelText: 'Location URL (Google Maps)',
                        hintText: 'https://maps.google.com/...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _registrationUrlController,
                      decoration: InputDecoration(
                        labelText: 'Registration URL',
                        hintText: 'https://...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        if (_selectedImage != null)
                          Container(
                            height: 200,
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.memory(
                                      _webImage!,
                                      fit: BoxFit.contain,
                                    )
                                  : Image.file(
                                      _selectedImage as File,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: Text(
                            _selectedImage == null ? 'Select Image' : 'Change Image',
                            style: GoogleFonts.poppins(),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            backgroundColor: Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Event Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _uploadEvent,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Create Event',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
