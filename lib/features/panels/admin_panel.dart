import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/models/app_user.dart';
import 'package:social_code/models/submission.dart';
import 'package:social_code/services/submission_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:social_code/services/auth_service.dart';
import 'package:social_code/models/challenge.dart';
import 'package:social_code/features/challenges/bloc/challenges_bloc.dart';
import 'package:social_code/core/widgets/challenge_image_picker.dart';
import 'package:social_code/core/utils/download.dart';

class AdminPanel extends StatefulWidget {
  final AppUser user;
  const AdminPanel({super.key, required this.user});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  List<Submission> _pending = [];
  Map<String, dynamic> _metrics = {};
  List<Challenge> _pendingChallenges = [];
  List<Challenge> _activeChallenges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_metrics.isEmpty) setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final svc = context.read<SubmissionService>();

      final pendingSubs = await svc.getPendingSubmissions();

      // Fetch all challenges
      final challsRaw = await client.from('challenges').select().order('created_at', ascending: false);
      final allChalls = (challsRaw as List).map((data) => Challenge.fromMap(data, data['id'])).toList();
      
      _pendingChallenges = allChalls.where((c) => c.status == ChallengeStatus.pending).toList();
      _activeChallenges = allChalls.where((c) => c.status == ChallengeStatus.active || c.status == ChallengeStatus.draft).toList();

      // Fetch metrics
      final profiles = await client.from('profiles').select('id');
      final resolvedReports = await client.from('civic_reports').select('id').eq('status', 'resolved');

      if (mounted) {
        setState(() {
          _pending = pendingSubs;
          _metrics = {
            'active_challenges': _activeChallenges.length,
            'citizens': (profiles as List).length,
            'resolved_reports': (resolvedReports as List).length,
            'pending_reviews': pendingSubs.length,
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reviewChallenge(String challengeId, bool approve) async {
    try {
      final status = approve ? ChallengeStatus.active.name : ChallengeStatus.draft.name;
      await Supabase.instance.client.from('challenges').update({'status': status}).eq('id', challengeId);
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? 'Challenge approved!' : 'Challenge rejected.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }
  
  Future<void> _deleteChallenge(String challengeId) async {
    try {
      await Supabase.instance.client.from('challenges').delete().eq('id', challengeId);
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Challenge deleted permanently.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red));
    }
  }

  void _showCreateForm(BuildContext context, {Challenge? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final briefingCtrl = TextEditingController(text: existing?.missionBriefing ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? 'Bengaluru');
    final pointsCtrl = TextEditingController(text: '${existing?.pointsReward ?? 50}');
    final targetCtrl = TextEditingController(text: '${existing?.targetCount ?? 100}');
    ChallengeCategory selectedCategory = existing?.category ?? ChallengeCategory.environment;
    String? selectedImageUrl = existing?.imageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(existing == null ? 'CREATE CHALLENGE' : 'EDIT CHALLENGE',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22)),
                const SizedBox(height: 20),

                ChallengeImagePicker(
                  initialImageUrl: existing?.imageUrl,
                  onUploaded: (url) => selectedImageUrl = url,
                ),
                const SizedBox(height: 16),

                _FormField(controller: titleCtrl, label: 'CHALLENGE TITLE'),
                const SizedBox(height: 12),
                _FormField(controller: descCtrl, label: 'DESCRIPTION', maxLines: 2),
                const SizedBox(height: 12),
                _FormField(controller: briefingCtrl, label: 'MISSION BRIEFING', maxLines: 3),
                const SizedBox(height: 12),

                Text('CATEGORY', style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ChallengeCategory.values.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setModal(() => selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryMagenta : Colors.white,
                            border: Border.all(color: isSelected ? AppTheme.primaryMagenta : AppTheme.borderBlack, width: 2),
                          ),
                          child: Text(cat.name.toUpperCase(), style: GoogleFonts.spaceMono(fontSize: 9, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.borderBlack)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _FormField(controller: pointsCtrl, label: 'POINTS', keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _FormField(controller: targetCtrl, label: 'TARGET', keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                _FormField(controller: cityCtrl, label: 'CITY'),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final isEditing = existing != null;
                      
                      try {
                        if (isEditing) {
                          await Supabase.instance.client.from('challenges').update({
                            'title': titleCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'mission_briefing': briefingCtrl.text.trim(),
                            'points_reward': int.tryParse(pointsCtrl.text) ?? 50,
                            'category': selectedCategory.name,
                            'city': cityCtrl.text.trim(),
                            'target_count': int.tryParse(targetCtrl.text) ?? 100,
                            if (selectedImageUrl != null) 'image_url': selectedImageUrl,
                          }).eq('id', existing.id);
                        } else {
                          final challenge = Challenge(
                            id: '',
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            missionBriefing: briefingCtrl.text.trim(),
                            creatorId: widget.user.id,
                            creatorName: widget.user.displayName,
                            startDate: DateTime.now(),
                            endDate: DateTime.now().add(const Duration(days: 30)),
                            pointsReward: int.tryParse(pointsCtrl.text) ?? 50,
                            category: selectedCategory,
                            city: cityCtrl.text.trim(),
                            targetCount: int.tryParse(targetCtrl.text) ?? 100,
                            status: ChallengeStatus.active,
                            imageUrl: selectedImageUrl,
                          );
                          await Supabase.instance.client.from('challenges').insert(challenge.toMap());
                        }
                        
                        if (mounted) {
                          _loadData();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Challenge updated!' : 'Challenge launched directly!')));
                        }
                      } catch (e) {
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    child: Text(existing == null ? 'LAUNCH IMMEDIATELY →' : 'SAVE CHANGES →'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryMagenta))
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COMMAND CENTER',
                          style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.borderBlack)),
                      const SizedBox(height: 4),
                      Text('OVERSEEING THE URBAN REVOLUTION',
                          style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: AppTheme.borderBlack.withOpacity(0.4),
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 28),

                      // Metrics grid
                      LayoutBuilder(builder: (ctx, constraints) {
                        final cols = constraints.maxWidth > 500 ? 4 : 2;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: cols,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                          children: [
                            _MetricCard('ACTIVE CODES',
                                '${_metrics['active_challenges'] ?? 0}',
                                Icons.flash_on, AppTheme.primaryMagenta),
                            _MetricCard('CITIZENS',
                                '${_metrics['citizens'] ?? 0}',
                                Icons.people, AppTheme.accentPurple),
                            _MetricCard('ISSUES RESOLVED',
                                '${_metrics['resolved_reports'] ?? 0}',
                                Icons.check_circle, Colors.green),
                            _MetricCard('PENDING REVIEWS',
                                '${_metrics['pending_reviews'] ?? 0}',
                                Icons.pending, Colors.orange),
                          ],
                        );
                      }),
                      const SizedBox(height: 36),

                      Row(
                        children: [
                          Text('VERIFICATION QUEUE',
                              style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0)),
                          const Spacer(),
                          Text('${_pending.length} PENDING',
                              style: GoogleFonts.spaceMono(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_pending.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppTheme.borderBlack.withOpacity(0.2)),
                          ),
                          child: Center(
                            child: Text(
                              '✓ ALL CAUGHT UP! NO PENDING REVIEWS.',
                              style: GoogleFonts.spaceMono(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _pending.length,
                          itemBuilder: (ctx, i) => _VerificationItem(
                            submission: _pending[i],
                            onApprove: () => _review(_pending[i].id, true),
                            onReject: () => _review(_pending[i].id, false),
                          ),
                        ),
                        
                      const SizedBox(height: 36),
                      Text('ROLE MANAGEMENT',
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 16),
                      const _RoleAssignmentSection(),

                      const SizedBox(height: 36),
                      Text('PENDING CODES',
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 16),
                      if (_pendingChallenges.isEmpty)
                        Text('No pending challenges awaiting approval.', style: TextStyle(color: AppTheme.borderBlack.withOpacity(0.5))),
                      ..._pendingChallenges.map((c) => _AdminChallengeItem(
                        challenge: c,
                        onApprove: () => _reviewChallenge(c.id, true),
                        onReject: () => _reviewChallenge(c.id, false),
                      )),

                      const SizedBox(height: 36),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ACTIVE CODES',
                              style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0)),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppTheme.primaryMagenta),
                            onPressed: () => _showCreateForm(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._activeChallenges.map((c) => _AdminChallengeItem(
                        challenge: c,
                        onEdit: () => _showCreateForm(context, existing: c),
                        onDelete: () => _deleteChallenge(c.id),
                      )),

                      const SizedBox(height: 36),
                      Text('DATA & INSIGHTS',
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 16),
                      const _AdminDataExport(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _review(String id, bool approve) async {
    final svc = context.read<SubmissionService>();
    if (approve) {
      await svc.approveSubmission(id);
    } else {
      await svc.rejectSubmission(id);
    }
    _loadData();
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderBlack, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.borderBlack)),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: AppTheme.borderBlack.withOpacity(0.5),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _VerificationItem extends StatelessWidget {
  final Submission submission;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _VerificationItem(
      {required this.submission, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderBlack, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Image.network(
                  submission.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: AppTheme.borderBlack.withOpacity(0.05),
                    child: const Icon(Icons.image, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BY ${submission.userName.toUpperCase()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    if (submission.caption != null)
                      Text(
                        submission.caption!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.borderBlack.withOpacity(0.5)),
                      ),
                    const SizedBox(height: 4),
                    if (submission.locationName != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 10, color: AppTheme.primaryMagenta),
                          const SizedBox(width: 2),
                          Text(submission.locationName!,
                              style: GoogleFonts.spaceMono(
                                  fontSize: 8,
                                  color: AppTheme.borderBlack.withOpacity(0.4))),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onReject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.borderBlack,
                    side: const BorderSide(color: AppTheme.borderBlack, width: 2),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text('REJECT',
                      style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMagenta,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text('APPROVE ✓',
                      style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminDataExport extends StatelessWidget {
  const _AdminDataExport();

  Future<void> _exportData(BuildContext context, String table) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fetching $table data...'), duration: const Duration(seconds: 1)),
      );
      final response = await Supabase.instance.client.from(table).select();
      if (response.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data found.')),
          );
        }
        return;
      }

      // Convert to CSV
      final headers = (response.first as Map<String, dynamic>).keys.join(',');
      final rows = response.map((row) {
        return (row as Map<String, dynamic>).values.map((v) {
          if (v == null) return '';
          final str = v.toString().replaceAll('"', '""');
          return '"$str"';
        }).join(',');
      }).join('\n');
      final csv = '$headers\n$rows';

      // Call our web-safe download helper
      final fileName = '${table}_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      downloadCsv(fileName, csv);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${response.length} rows from $table downloaded as CSV!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting $table: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ExportButton('DOWNLOAD CITIZEN PROFILES', Icons.people, () => _exportData(context, 'profiles')),
        const SizedBox(height: 12),
        _ExportButton('DOWNLOAD ALL CHALLENGES', Icons.flash_on, () => _exportData(context, 'challenges')),
        const SizedBox(height: 12),
        _ExportButton('DOWNLOAD ALL SUBMISSIONS', Icons.photo_library, () => _exportData(context, 'submissions')),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ExportButton(this.label, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: AppTheme.borderBlack),
        label: Text(label, style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, color: AppTheme.borderBlack)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.borderBlack, width: 2),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _RoleAssignmentSection extends StatefulWidget {
  const _RoleAssignmentSection();
  @override
  State<_RoleAssignmentSection> createState() => _RoleAssignmentSectionState();
}

class _RoleAssignmentSectionState extends State<_RoleAssignmentSection> {
  final _emailCtrl = TextEditingController();
  UserRole _selectedRole = UserRole.creator;
  bool _isLoading = false;

  Future<void> _assignRole() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().assignRoleByEmail(email, _selectedRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assigned ${_selectedRole.name.toUpperCase()} role to $email!'), backgroundColor: Colors.green));
        _emailCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentPurple.withOpacity(0.05),
        border: Border.all(color: AppTheme.accentPurple, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'User Email',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<UserRole>(
            value: _selectedRole,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
            items: const [
              DropdownMenuItem(value: UserRole.admin, child: Text('ADMIN')),
              DropdownMenuItem(value: UserRole.creator, child: Text('CREATOR')),
            ],
            onChanged: (v) => setState(() => _selectedRole = v!),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
              onPressed: _isLoading ? null : _assignRole,
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('ASSIGN ROLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminChallengeItem extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _AdminChallengeItem({
    required this.challenge,
    this.onApprove,
    this.onReject,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderBlack, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(challenge.title.toUpperCase(),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              if (onEdit != null)
                IconButton(icon: const Icon(Icons.edit, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: onEdit),
              if (onDelete != null) ...[
                const SizedBox(width: 12),
                IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: onDelete),
              ]
            ],
          ),
          const SizedBox(height: 4),
          Text('BY: ${challenge.creatorName.toUpperCase()}', style: GoogleFonts.spaceMono(fontSize: 10, color: AppTheme.borderBlack.withOpacity(0.5))),
          const SizedBox(height: 12),
          if (onApprove != null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                    child: Text('REJECT', style: GoogleFonts.spaceMono(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                    child: Text('APPROVE', style: GoogleFonts.spaceMono(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  const _FormField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.borderBlack, width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.primaryMagenta, width: 2)),
          ),
        ),
      ],
    );
  }
}
