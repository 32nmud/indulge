import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class PersonImagePicker extends StatefulWidget {
  final String? initialImageBytes;
  final ValueChanged<String?> onImageChanged;

  const PersonImagePicker({
    super.key,
    this.initialImageBytes,
    required this.onImageChanged,
  });

  @override
  State<PersonImagePicker> createState() => _PersonImagePickerState();
}

class _PersonImagePickerState extends State<PersonImagePicker> {
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialImageBytes != null) {
      try {
        _imageBytes = base64Decode(widget.initialImageBytes!);
      } catch (e) {
        debugPrint('Error decoding initial image bytes: $e');
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      final Uint8List bytes = await pickedFile.readAsBytes();

      // Compress the image
      final Uint8List result = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 512,
        minWidth: 512,
        quality: 70,
      );

      setState(() {
        _imageBytes = result;
      });

      final String base64String = base64Encode(result);
      widget.onImageChanged(base64String);
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSourceSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_imageBytes != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageBytes = null;
                  });
                  widget.onImageChanged(null);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _showSourceSelector,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: colorScheme.surfaceContainerHighest,
              backgroundImage: _imageBytes != null
                  ? MemoryImage(_imageBytes!)
                  : null,
              child: _imageBytes == null
                  ? Icon(
                      Icons.person,
                      size: 60,
                      color: colorScheme.onSurfaceVariant,
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showSourceSelector,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
