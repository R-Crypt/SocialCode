import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/models/app_user.dart';
import 'package:social_code/models/challenge.dart';
import 'package:social_code/services/submission_service.dart';

class SubmitProofScreen extends StatefulWidget {
  final Challenge challenge;
  final AppUser user;
  const SubmitProofScreen({super.key, required this.challenge, required this.user});

  @override
  State<SubmitProofScreen> createState() => _SubmitProofScreenState();
}

class _SubmitProofScreenState extends State<SubmitProofScreen> {
  XFile? _image;
  final _captionController = TextEditingController();
  Position? _position;
  bool _submitting = false;
  bool _submitted = false;
  bool _gettingLocation = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _gettingLocation = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _gettingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() { _position = pos; _gettingLocation = false; });
    } catch (_) {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 80);
    if (image != null && mounted) setState(() => _image = image);
  }

  Future<void> _submit() async {
    if (_image == null) return;
    setState(() => _submitting = true);
    try {
      final service = context.read<SubmissionService>();
      await service.submitProof(
        challengeId: widget.challenge.id,
        userId: widget.user.id,
        userName: widget.user.displayName,
        imageFilePath: _image!.path,
        caption: _captionController.text.trim().isNotEmpty
            ? _captionController.text.trim()
            : null,
        latitude: _position?.latitude,
        longitude: _position?.longitude,
        locationName: _position != null
            ? '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}'
            : null,
      );
      if (mounted) setState(() { _submitting = false; _submitted = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SUBMISSION FAILED: ${e.toString()}'),
            backgroundColor: AppTheme.primaryMagenta,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _SuccessScreen(challenge: widget.challenge);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'SUBMIT PROOF',
          style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.w900, color: AppTheme.borderBlack, fontSize: 14),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryMagenta.withOpacity(0.05),
                border: Border.all(color: AppTheme.primaryMagenta, width: 2),
              ),
              child: Text(
                'MISSION: ${widget.challenge.title.toUpperCase()}',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppTheme.primaryMagenta,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Image picker
            Text('PROOF PHOTO',
                style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppTheme.borderBlack)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showImageSourceSheet(),
              child: Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: _image == null
                        ? AppTheme.borderBlack.withOpacity(0.15)
                        : AppTheme.borderBlack,
                    width: 2,
                  ),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              color: AppTheme.borderBlack.withOpacity(0.3),
                              size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'TAP TO ADD YOUR PROOF',
                            style: GoogleFonts.spaceMono(
                              color: AppTheme.borderBlack.withOpacity(0.3),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'CAMERA OR GALLERY',
                            style: GoogleFonts.spaceMono(
                              color: AppTheme.borderBlack.withOpacity(0.2),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      )
                    : Image.file(File(_image!.path), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),

            // Location
            Text('LOCATION',
                style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppTheme.borderBlack)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.borderBlack, width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: _position != null
                        ? AppTheme.primaryMagenta
                        : AppTheme.borderBlack.withOpacity(0.3),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _gettingLocation
                        ? Text('GETTING LOCATION...',
                            style: GoogleFonts.spaceMono(
                                fontSize: 11,
                                color: AppTheme.borderBlack.withOpacity(0.4)))
                        : _position != null
                            ? Text(
                                '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}',
                                style: GoogleFonts.spaceMono(
                                    fontSize: 11,
                                    color: AppTheme.borderBlack,
                                    fontWeight: FontWeight.bold))
                            : Text('LOCATION UNAVAILABLE',
                                style: GoogleFonts.spaceMono(
                                    fontSize: 11,
                                    color: AppTheme.borderBlack.withOpacity(0.4))),
                  ),
                  if (_position != null)
                    Text('VERIFIED',
                        style: GoogleFonts.spaceMono(
                            color: AppTheme.primaryMagenta,
                            fontSize: 9,
                            fontWeight: FontWeight.w900)),
                  if (!_gettingLocation && _position == null)
                    TextButton(
                        onPressed: _getLocation,
                        child: Text('RETRY',
                            style: GoogleFonts.spaceMono(
                                fontSize: 10, color: AppTheme.accentPurple))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Caption
            Text('YOUR STORY',
                style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppTheme.borderBlack)),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLines: 4,
              style: GoogleFonts.inter(color: AppTheme.borderBlack, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'TELL THE STORY BEHIND YOUR ACTION...',
                hintStyle: TextStyle(color: AppTheme.borderBlack.withOpacity(0.2)),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppTheme.borderBlack, width: 2),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppTheme.primaryMagenta, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_image == null || _submitting) ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('SUBMIT TO THE CODE →'),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'YOUR SUBMISSION WILL BE REVIEWED BEFORE POINTS ARE AWARDED',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  color: AppTheme.borderBlack.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceSheet() {
    // On macOS/desktop, camera is not supported - open gallery directly
    final isDesktop = kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    if (isDesktop) {
      _pickImage(ImageSource.gallery);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ADD YOUR PROOF',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.camera_alt,
                    label: 'CAMERA',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library,
                    label: 'GALLERY',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderBlack, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryMagenta),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.spaceMono(
                    fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final Challenge challenge;
  const _SuccessScreen({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: AppTheme.primaryMagenta),
              const SizedBox(height: 24),
              Text(
                'PROOF SUBMITTED!',
                style: GoogleFonts.outfit(
                    fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.borderBlack),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'YOUR SUBMISSION FOR "${challenge.title.toUpperCase()}" IS IN REVIEW.\nPOINTS WILL BE AWARDED UPON APPROVAL.',
                style: GoogleFonts.spaceMono(
                  color: AppTheme.borderBlack.withOpacity(0.5),
                  fontSize: 11,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                  child: const Text('BACK TO CODES'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
