import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';
import '../services/user_service.dart';

// TODO: Implement actual image upload functionality
// For now, we'll just simulate the upload with a delay

class UserProfileWidget extends StatefulWidget {
  final UserModel user;
  final Function(String) onProfileUpdated;

  const UserProfileWidget({
    Key? key,
    required this.user,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<UserProfileWidget> createState() => _UserProfileWidgetState();
}

class _UserProfileWidgetState extends State<UserProfileWidget> {
  final _userService = UserService();

  Future<void> _updateProfileImage(BuildContext context) async {
    try {
      print('Starting profile image update');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, // Limit image size
        maxHeight: 512,
        imageQuality: 70, // Compress image
      );
      
      if (image != null) {
        print('Image selected: ${image.path}');
        dynamic imageData;
        if (kIsWeb) {
          imageData = await image.readAsBytes();
          print('Web: Converted image to bytes, size: ${imageData.length}');
        } else {
          imageData = File(image.path);
          print('Mobile: Using file path: ${image.path}');
        }

        print('Uploading image to Firebase');
        final imageUrl = await _userService.updateProfileImage(imageData);
        print('Got image URL: $imageUrl');
        widget.onProfileUpdated(imageUrl);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully')),
          );
        }
      } else {
        print('No image selected');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 56),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          radius: 20,
          backgroundImage: widget.user.profileImageUrl != null
              ? NetworkImage(widget.user.profileImageUrl!)
              : null,
          child: widget.user.profileImageUrl == null
              ? Text(widget.user.name[0].toUpperCase())
              : null,
        ),
      ),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          child: ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: widget.user.profileImageUrl != null
                  ? NetworkImage(widget.user.profileImageUrl!)
                  : null,
              child: widget.user.profileImageUrl == null
                  ? Text(widget.user.name[0].toUpperCase(), style: const TextStyle(fontSize: 20))
                  : null,
            ),
            title: Text(widget.user.name),
            subtitle: Text(widget.user.email),
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Update Profile Picture'),
            onTap: () {
              Navigator.pop(context);
              _updateProfileImage(context);
            },
          ),
        ),
        if (widget.user.role == 'student') ...[
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.school),
              title: Text('Department: ${widget.user.department ?? "N/A"}'),
            ),
          ),
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Year: ${widget.user.year ?? "N/A"}'),
            ),
          ),
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.badge),
              title: Text('Reg No: ${widget.user.studentId ?? "N/A"}'),
            ),
          ),
        ] else if (widget.user.role == 'admin') ...[
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.work),
              title: Text('Staff ID: ${widget.user.staffId ?? "N/A"}'),
            ),
          ),
        ],
      ],
    );
  }
}
