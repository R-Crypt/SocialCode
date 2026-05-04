import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/features/auth/bloc/auth_bloc.dart';
import 'package:social_code/models/app_user.dart';
import 'package:social_code/models/submission.dart';
import 'package:social_code/services/submission_service.dart';
import 'package:social_code/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Submission> _submissions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      final svc = context.read<SubmissionService>();
      final subs = await svc.getUserSubmissions(widget.user.id);
      if (mounted) setState(() { _submissions = subs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final approved = _submissions.where((s) => s.status == SubmissionStatus.approved).length;
    final pending = _submissions.where((s) => s.status == SubmissionStatus.pending).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        if (Navigator.canPop(context)) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                        ],
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppTheme.primaryMagenta.withOpacity(0.1),
                          backgroundImage: user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                          child: user.profileImageUrl == null
                              ? Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 28,
                                      color: AppTheme.primaryMagenta),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName.toUpperCase(),
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w900, fontSize: 22),
                              ),
                              Text(
                                user.email,
                                style: TextStyle(
                                    color: AppTheme.borderBlack.withOpacity(0.4),
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentPurple.withOpacity(0.1),
                                  border: Border.all(
                                      color: AppTheme.accentPurple, width: 1.5),
                                ),
                                child: Text(
                                  user.role.name.toUpperCase(),
                                  style: GoogleFonts.spaceMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentPurple),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditProfileSheet(context),
                        ),
                        if (!Navigator.canPop(context)) ...[
                          IconButton(
                            icon: const Icon(Icons.logout),
                            onPressed: () =>
                                context.read<AuthBloc>().add(LogoutRequested()),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats row
                    Row(
                      children: [
                        _StatBox(label: 'POINTS', value: '${user.points}',
                            color: AppTheme.primaryMagenta),
                        const SizedBox(width: 12),
                        _StatBox(label: 'APPROVED', value: '$approved',
                            color: Colors.green),
                        const SizedBox(width: 12),
                        _StatBox(label: 'PENDING', value: '$pending',
                            color: Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Region
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: AppTheme.primaryMagenta),
                        const SizedBox(width: 6),
                        Text(user.region,
                            style: GoogleFonts.spaceMono(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.borderBlack.withOpacity(0.6))),
                      ],
                    ),

                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(user.bio!,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.borderBlack.withOpacity(0.7),
                              height: 1.5)),
                    ],

                    if (user.role == UserRole.creator) ...[
                      const SizedBox(height: 16),
                      if (user.creatorDetails != null && user.creatorDetails!.isNotEmpty) ...[
                        Text('UPCOMING MOVEMENTS',
                            style: GoogleFonts.spaceMono(
                                fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryMagenta)),
                        const SizedBox(height: 4),
                        Text(user.creatorDetails!,
                            style: GoogleFonts.inter(
                                fontSize: 14, color: AppTheme.borderBlack, height: 1.5)),
                        const SizedBox(height: 16),
                      ],
                      if (user.websiteUrl != null && user.websiteUrl!.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.link, size: 16, color: AppTheme.borderBlack),
                            const SizedBox(width: 6),
                            Text(user.websiteUrl!,
                                style: GoogleFonts.spaceMono(
                                    fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.borderBlack)),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (user.instagramUrl != null && user.instagramUrl!.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.camera_alt_outlined, size: 16, color: AppTheme.borderBlack),
                            const SizedBox(width: 6),
                            Text('@${user.instagramUrl!.split('/').last}',
                                style: GoogleFonts.spaceMono(
                                    fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.borderBlack)),
                          ],
                        ),
                      ],
                    ],

                    const SizedBox(height: 24),

                    const SizedBox(height: 32),
                    Text('MY SUBMISSIONS',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Submissions grid
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryMagenta)),
              )
            else if (_submissions.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 48,
                          color: AppTheme.borderBlack.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      Text('NO SUBMISSIONS YET.',
                          style: GoogleFonts.spaceMono(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.borderBlack.withOpacity(0.4))),
                      const SizedBox(height: 4),
                      Text('JOIN A MISSION AND SUBMIT PROOF.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.borderBlack.withOpacity(0.3))),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _SubmissionTile(
                        submission: _submissions[index]),
                    childCount: _submissions.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final user = widget.user;
    final nameController = TextEditingController(text: user.displayName);
    final bioController = TextEditingController(text: user.bio);
    final instaController = TextEditingController(text: user.instagramUrl);
    final webController = TextEditingController(text: user.websiteUrl);
    final detailsController = TextEditingController(text: user.creatorDetails);
    
    XFile? newImage;
    Uint8List? newImageBytes;
    bool isSaving = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('EDIT PROFILE',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final img = await picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 80);
                        if (img != null) {
                          final bytes = await img.readAsBytes();
                          setState(() {
                            newImage = img;
                            newImageBytes = bytes;
                          });
                        }
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryMagenta.withOpacity(0.1),
                        backgroundImage: newImageBytes != null
                            ? MemoryImage(newImageBytes!)
                            : (user.profileImageUrl != null
                                ? NetworkImage(user.profileImageUrl!)
                                : null) as ImageProvider?,
                        child: (newImageBytes == null && user.profileImageUrl == null)
                            ? const Icon(Icons.camera_alt, color: AppTheme.primaryMagenta)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('TAP TO CHANGE PHOTO',
                        style: GoogleFonts.spaceMono(
                            fontSize: 10, color: AppTheme.primaryMagenta)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'USERNAME',
                        errorText: errorText,
                        labelStyle: GoogleFonts.spaceMono(
                            fontSize: 12, fontWeight: FontWeight.bold),
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'BIO',
                        labelStyle: GoogleFonts.spaceMono(
                            fontSize: 12, fontWeight: FontWeight.bold),
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
                    if (user.role == UserRole.creator) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: detailsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'UPCOMING MOVEMENTS / DETAILS',
                          labelStyle: GoogleFonts.spaceMono(
                              fontSize: 12, fontWeight: FontWeight.bold),
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: webController,
                        decoration: InputDecoration(
                          labelText: 'WEBSITE URL',
                          labelStyle: GoogleFonts.spaceMono(
                              fontSize: 12, fontWeight: FontWeight.bold),
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: instaController,
                        decoration: InputDecoration(
                          labelText: 'INSTAGRAM URL',
                          labelStyle: GoogleFonts.spaceMono(
                              fontSize: 12, fontWeight: FontWeight.bold),
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
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final newName = nameController.text.trim();
                                if (newName.isEmpty) {
                                  setState(() => errorText = 'USERNAME CANNOT BE EMPTY');
                                  return;
                                }

                                setState(() {
                                  isSaving = true;
                                  errorText = null;
                                });

                                try {
                                  final svc = context.read<AuthService>();
                                  
                                  // Check unique display name
                                  if (newName != user.displayName) {
                                    final exists = await Supabase.instance.client
                                        .from('profiles')
                                        .select('id')
                                        .eq('display_name', newName)
                                        .maybeSingle();
                                    if (exists != null && exists['id'] != user.id) {
                                      setState(() {
                                        errorText = 'USERNAME ALREADY TAKEN';
                                        isSaving = false;
                                      });
                                      return;
                                    }
                                  }

                                  String? newUrl;
                                  if (newImageBytes != null) {
                                    newUrl = await svc.uploadAvatarImage(newImageBytes!, user.id);
                                  }

                                  await svc.updateProfile(
                                    userId: user.id,
                                    displayName: newName,
                                    profileImageUrl: newUrl,
                                    bio: bioController.text.trim(),
                                    instagramUrl: instaController.text.trim(),
                                    websiteUrl: webController.text.trim(),
                                    creatorDetails: detailsController.text.trim(),
                                  );

                                  if (mounted) {
                                    // Trigger reload
                                    context.read<AuthBloc>().add(AppStarted());
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  setState(() {
                                    errorText = 'FAILED TO UPDATE PROFILE: $e';
                                    isSaving = false;
                                  });
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('SAVE CHANGES'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.borderBlack.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final Submission submission;
  const _SubmissionTile({required this.submission});

  Color get _statusColor {
    switch (submission.status) {
      case SubmissionStatus.approved: return Colors.green;
      case SubmissionStatus.pending: return Colors.orange;
      case SubmissionStatus.rejected: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderBlack, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(
              submission.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.borderBlack.withOpacity(0.05),
                child: const Icon(Icons.broken_image, size: 32),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: _statusColor,
            child: Text(
              submission.status.name.toUpperCase(),
              style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
