import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';

class SubmitProofScreen extends StatefulWidget {
  const SubmitProofScreen({super.key});

  @override
  State<SubmitProofScreen> createState() => _SubmitProofScreenState();
}

class _SubmitProofScreenState extends State<SubmitProofScreen> {
  XFile? _image;
  final _captionController = TextEditingController();

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    setState(() => _image = image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text('SUBMIT PROOF', style: GoogleFonts.outfit(fontWeight: FontWeight.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Upload Area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _image == null ? AppTheme.neonGreen.withOpacity(0.3) : AppTheme.neonGreen,
                    width: 2,
                    style: _image == null ? BorderStyle.solid : BorderStyle.solid,
                  ),
                ),
                child: _image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo, color: AppTheme.neonGreen, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'TAP TO SNAP THE PROOF',
                          style: GoogleFonts.outfit(
                            color: AppTheme.neonGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.network(_image!.path, fit: BoxFit.cover), // Placeholder for local file
                    ),
              ),
            ),
            const SizedBox(height: 32),

            // Metadata
            Text(
              'LOCATION & CAPTION',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white60,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            
            // Location Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: AppTheme.accentPink, size: 20),
                  SizedBox(width: 8),
                  Text('Indiranagar, Bangalore', style: TextStyle(color: Colors.white70)),
                  Spacer(),
                  Text('VERIFIED', style: TextStyle(color: AppTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tell the story behind your flex...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _image == null ? null : () {
                  // TODO: Upload to Firebase
                },
                child: const Text('SUBMIT TO THE CODE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
