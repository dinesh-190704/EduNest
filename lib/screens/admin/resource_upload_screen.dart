import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:io' as io;
import '../../models/resource_model.dart';
import '../../services/resource_service.dart';
import 'package:uuid/uuid.dart';

class ResourceUploadScreen extends StatefulWidget {
  final String category;

  const ResourceUploadScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<ResourceUploadScreen> createState() => _ResourceUploadScreenState();
}

class _ResourceUploadScreenState extends State<ResourceUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _resourceService = ResourceService();
  final _uuid = Uuid();

  String _title = '';
  String _description = '';
  String _subject = '';
  int _semester = 1;
  PlatformFile? _selectedFile;
  Uint8List? _selectedFileBytes;
  io.File? _selectedLocalFile;
  bool _isUploading = false;
  String? _fileName;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _fileName = result.files.first.name;

          if (kIsWeb) {
            _selectedFileBytes = result.files.first.bytes;
          } else {
            if (result.files.first.path != null) {
              _selectedLocalFile = io.File(result.files.first.path!);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadResource() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (kIsWeb && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: File content is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!kIsWeb && _selectedLocalFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not access the file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isUploading = true);

    try {
      // Upload file to Firebase Storage
      final fileUrl = await _resourceService.uploadFile(_selectedFile!, widget.category);
      
      // Create resource document
      final resource = Resource(
        id: _uuid.v4(),
        title: _title,
        fileUrl: fileUrl,
        fileType: _fileName!.split('.').last.toLowerCase(),
        uploadDate: DateTime.now().toIso8601String(),
        category: widget.category,
        subject: _subject,
        semester: _semester,
        description: _description,
      );

      // Add to Firestore
      await _resourceService.addResource(resource);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.category == 'notes'
                  ? 'Lecture notes uploaded successfully!'
                  : 'Question paper uploaded successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error uploading resource: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload ${widget.category == 'notes' ? 'Notes' : 'Question Paper'}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  onSaved: (value) => _title = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  onSaved: (value) => _description = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                  onSaved: (value) => _subject = value!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    border: OutlineInputBorder(),
                  ),
                  value: _semester,
                  items: List.generate(8, (index) => index + 1)
                      .map((semester) => DropdownMenuItem(
                            value: semester,
                            child: Text('Semester $semester'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _semester = value!),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: Text(_selectedFile == null
                      ? 'Select File'
                      : 'Selected: ${_selectedFile!.name}'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                if (_selectedFile != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'File size: ${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isUploading ? null : () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _uploadResource();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Upload',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
