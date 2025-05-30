import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/lost_found_item.dart';
import '../../services/lost_found_service.dart';

class AddLostFoundItem extends StatefulWidget {
  const AddLostFoundItem({Key? key}) : super(key: key);

  @override
  _AddLostFoundItemState createState() => _AddLostFoundItemState();
}

class _AddLostFoundItemState extends State<AddLostFoundItem> {
  // UI Theme
  final _borderRadius = 12.0;
  final _inputPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  final _buttonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
  final _inputDecoration = (String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
    ),
    filled: true,
    fillColor: Colors.grey[50],
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  
  ItemStatus _status = ItemStatus.lost;
  ItemCategory _category = ItemCategory.other;
  DateTime _date = DateTime.now();
  dynamic _image;
  Uint8List? _webImage;
  bool _anonymousContact = false;
  String? _imageName;
  
  final LostFoundService _service = LostFoundService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      if (kIsWeb) {
        // Handle web image
        final bytes = await image.readAsBytes();
        setState(() {
          _webImage = bytes;
          _image = bytes;
          _imageName = image.name;
        });
      } else {
        // Handle mobile image
        setState(() {
          _image = File(image.path);
          _imageName = image.name;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final item = LostFoundItem(
          id: const Uuid().v4(),
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          date: _date,
          status: _status,
          category: _category,
          userId: FirebaseAuth.instance.currentUser?.uid ?? '', // Get current user ID
          anonymousContact: _anonymousContact,
          contactInfo: _anonymousContact ? null : _contactController.text,
          createdAt: DateTime.now(),
          isResolved: false,
        );

        await _service.createItem(item, _image);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item reported successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Item',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
                padding: const EdgeInsets.all(4),
                child: SegmentedButton<ItemStatus>(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.white;
                        }
                        return Colors.transparent;
                      },
                    ),
                    side: MaterialStateProperty.all(BorderSide.none),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_borderRadius - 4),
                    )),
                  ),
                  segments: [
                    ButtonSegment(
                      value: ItemStatus.lost,
                      label: Text('Lost Item',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500)),
                      icon: const Icon(Icons.search),
                    ),
                    ButtonSegment(
                      value: ItemStatus.found,
                      label: Text('Found Item',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500)),
                      icon: const Icon(Icons.check_circle),
                    ),
                  ],
                  selected: {_status},
                  onSelectionChanged: (Set<ItemStatus> newSelection) {
                    setState(() {
                      _status = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Item Name*', Icons.inventory),
                style: GoogleFonts.poppins(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_borderRadius),
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: DropdownButtonFormField<ItemCategory>(
                  value: _category,
                  decoration: _inputDecoration('Category*', Icons.category),
                  dropdownColor: Colors.grey[50],
                  items: ItemCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        category.toString().split('.').last,
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  }).toList(),
                  onChanged: (ItemCategory? value) {
                    if (value != null) {
                      setState(() {
                        _category = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Location*', Icons.location_on),
                style: GoogleFonts.poppins(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _date = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date*',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '${_date.year}-${_date.month}-${_date.day}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Description*', Icons.description),
                style: GoogleFonts.poppins(),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_camera),
                label: Text('Add Photo',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                style: _buttonStyle,
              ),
              if (_image != null) ...[                
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_borderRadius),
                    child: kIsWeb
                        ? Image.memory(
                            _webImage!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            _image as File,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _imageName ?? 'Selected Image',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(_borderRadius),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: SwitchListTile(
                  title: Text('Anonymous Contact',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                      'Hide your contact information from other users',
                      style: GoogleFonts.poppins(fontSize: 12)),
                  value: _anonymousContact,
                  onChanged: (bool value) {
                    setState(() {
                      _anonymousContact = value;
                    });
                  },
                ),
              ),
              if (!_anonymousContact) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Information',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!_anonymousContact && (value == null || value.isEmpty)) {
                      return 'Please enter contact information';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: _buttonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(Colors.blue[700]),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  child: Text(
                    'Submit Report',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
