import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_code/core/theme/app_theme.dart';

/// A widget that lets a user pick an image from their gallery,
/// uploads it to Supabase Storage, and exposes the public URL via [onUploaded].
class ChallengeImagePicker extends StatefulWidget {
  final String? initialImageUrl;
  final void Function(String imageUrl) onUploaded;

  const ChallengeImagePicker({
    super.key,
    this.initialImageUrl,
    required this.onUploaded,
  });

  @override
  State<ChallengeImagePicker> createState() => _ChallengeImagePickerState();
}

class _ChallengeImagePickerState extends State<ChallengeImagePicker> {
  String? _previewUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _previewUrl = widget.initialImageUrl;
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploading = true);

    try {
      final Uint8List bytes = await picked.readAsBytes();
      final fileName = 'challenge_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final client = Supabase.instance.client;

      await client.storage.from('challenge-images').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final publicUrl = client.storage
          .from('challenge-images')
          .getPublicUrl(fileName);

      setState(() {
        _previewUrl = publicUrl;
        _uploading = false;
      });

      widget.onUploaded(publicUrl);
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _uploading ? null : _pickAndUpload,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(
            color: AppTheme.primaryMagenta,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _uploading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryMagenta),
              )
            : _previewUrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(_previewUrl!, fit: BoxFit.cover),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          color: Colors.black87,
                          child: Text(
                            'TAP TO CHANGE',
                            style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 40, color: AppTheme.primaryMagenta),
                      SizedBox(height: 8),
                      Text(
                        'TAP TO ADD CHALLENGE IMAGE',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryMagenta,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
