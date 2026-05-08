import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/models/app_user.dart';
import 'package:social_code/models/submission.dart';
import 'package:social_code/services/submission_service.dart';
import 'package:social_code/features/panels/admin_users_screen.dart';
import 'package:social_code/features/challenges/screens/challenges_list_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:social_code/services/auth_service.dart';
import 'package:social_code/models/challenge.dart';
import 'package:social_code/models/civic_report.dart';
import 'package:social_code/services/report_service.dart';
import 'package:social_code/features/challenges/bloc/challenges_bloc.dart';
import 'package:social_code/core/widgets/challenge_image_picker.dart';
import 'package:social_code/core/utils/download.dart';
import 'package:intl/intl.dart';
import 'package:social_code/models/event.dart';
import 'package:social_code/services/event_service.dart';
import 'package:social_code/features/events/screens/gate_check_screen.dart';
import 'package:social_code/features/events/screens/events_list_screen.dart';

class AdminPanel extends StatefulWidget {
  final AppUser user;
  final VoidCallback? onNavigateToCodes;
  const AdminPanel({super.key, required this.user, this.onNavigateToCodes});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  List<Submission> _pendingReviews = [];
  List<CivicReport> _pendingIssues = [];
  List<CivicReport> _resolvedIssues = [];
  Map<String, dynamic> _metrics = {};
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
      final subSvc = context.read<SubmissionService>();
      final reportSvc = context.read<ReportService>();

      final pendingSubs = await subSvc.getPendingSubmissions();
      final allReports = await reportSvc.getReports();
      final pendingIssues = allReports.where((r) => r.status == ReportStatus.reported || r.status == ReportStatus.in_progress).toList();

      final challsRaw = await client.from('challenges').select().order('created_at', ascending: false);
      final allChalls = (challsRaw as List).map((data) => Challenge.fromMap(data, data['id'])).toList();
      _activeChallenges = allChalls;

      final profiles = await client.from('profiles').select('id');
      final resolvedReports = allReports.where((r) => r.status == ReportStatus.resolved).toList();

      if (mounted) {
        setState(() {
          _pendingReviews = pendingSubs;
          _pendingIssues = pendingIssues;
          _resolvedIssues = resolvedReports;
          _metrics = {
            'active_challenges': allChalls.length,
            'citizens': (profiles as List).length,
            'resolved_reports': resolvedReports.length,
            'pending_reviews': pendingSubs.length,
            'pending_issues': pendingIssues.length,
            'resolved': resolvedReports.length,
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateForm(BuildContext context, {Challenge? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final briefingCtrl = TextEditingController(text: existing?.missionBriefing ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? 'Bengaluru');
    final artistCtrl = TextEditingController(text: existing?.artistName ?? '');
    final pointsCtrl = TextEditingController(text: '${existing?.pointsReward ?? 50}');
    final targetCtrl = TextEditingController(text: '${existing?.targetCount ?? 100}');
    ChallengeCategory selectedCategory = existing?.category ?? ChallengeCategory.environment;
    String? selectedImageUrl = existing?.imageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                SizedBox(height: 20),

                ChallengeImagePicker(
                  initialImageUrl: existing?.imageUrl,
                  onUploaded: (url) => selectedImageUrl = url,
                ),
                SizedBox(height: 16),

                _FormField(controller: titleCtrl, label: 'CHALLENGE TITLE'),
                SizedBox(height: 12),
                _FormField(controller: artistCtrl, label: 'ARTIST / CREATOR NAME'),
                SizedBox(height: 12),
                _FormField(controller: descCtrl, label: 'DESCRIPTION', maxLines: 2),
                SizedBox(height: 12),
                _FormField(controller: briefingCtrl, label: 'MISSION BRIEFING', maxLines: 3),
                SizedBox(height: 12),

                Text('CATEGORY', style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ChallengeCategory.values.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setModal(() => selectedCategory = cat),
                        child: Container(
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryMagenta : Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? AppTheme.primaryMagenta : Theme.of(context).colorScheme.outline),
                          ),
                          child: Text(cat.name.toUpperCase(), 
                            style: GoogleFonts.spaceMono(fontSize: 9, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _FormField(controller: pointsCtrl, label: 'POINTS', keyboardType: TextInputType.number)),
                    SizedBox(width: 12),
                    Expanded(child: _FormField(controller: targetCtrl, label: 'TARGET', keyboardType: TextInputType.number)),
                  ],
                ),
                SizedBox(height: 12),
                _FormField(controller: cityCtrl, label: 'CITY'),
                SizedBox(height: 24),

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
                            'artist_name': artistCtrl.text.trim(),
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
                            artistName: artistCtrl.text.trim(),
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
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Challenge updated!' : 'Challenge launched!')));
                        }
                      } catch (e) {
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    child: Text(existing == null ? 'LAUNCH CHALLENGE →' : 'SAVE CHANGES →'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryMagenta))
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COMMAND CENTER',
                          style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.w900)),
                      Text('ADMINISTRATIVE OVERVIEW',
                          style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: AppTheme.textDim,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 28),

                      // Metrics grid
                      _buildMetricsGrid(),
                      SizedBox(height: 36),

                      _buildPendingIssuesBox(),
                      SizedBox(height: 36),

                      _buildResolvedIssuesBox(),
                      SizedBox(height: 36),

                      _buildPendingReviewsBox(),
                      SizedBox(height: 36),

                      _buildChallengesSection(),
                      SizedBox(height: 36),

                      Text('ROLE MANAGEMENT',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      const _RoleAssignmentSection(),

                      SizedBox(height: 36),
                      _AdminEventsSection(user: widget.user),

                      SizedBox(height: 36),
                      Text('DATA & INSIGHTS',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      const _AdminDataExport(),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth > 600 ? 4 : 2;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
        children: [
          _MetricCard(
            label: 'CITIZENS', 
            value: '${_metrics['citizens']}', 
            icon: Icons.people, 
            color: AppTheme.accentPurple,
            onTap: () {
              // Scroll to user management or show dialog
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CITIZEN LIST LOADING...')));
            },
          ),
          _MetricCard(
            label: 'PENDING REVIEWS', 
            value: '${_metrics['pending_reviews']}', 
            icon: Icons.pending_actions, 
            color: Colors.orange,
            onTap: () {
              _scrollController.animateTo(
                400, // Approximate position of pending reviews
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
          ),
          _MetricCard(
            label: 'PENDING ISSUES', 
            value: '${_metrics['pending_issues']}', 
            icon: Icons.warning_amber_rounded, 
            color: Colors.red,
            onTap: () {
               _scrollController.animateTo(
                200, // Approximate position of pending issues
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
          ),
          _MetricCard(
            label: 'RESOLVED', 
            value: '${_metrics['resolved']}', 
            icon: Icons.check_circle_outline, 
            color: Colors.green,
            onTap: () {
               _scrollController.animateTo(
                300, // Approximate position of resolved issues
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      );
    });
  }

  Widget _buildPendingIssuesBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PENDING ISSUES', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${_pendingIssues.length} TOTAL', style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: _pendingIssues.isEmpty 
            ? const Center(child: Text('All issues resolved!'))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pendingIssues.length.clamp(0, 5),
                separatorBuilder: (_, __) => Divider(),
                itemBuilder: (ctx, i) {
                  final issue = _pendingIssues[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(issue.categoryEmoji, style: TextStyle(fontSize: 20)),
                    title: Text(issue.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('By ${issue.userName} · ${issue.locationName ?? "Unknown location"}', style: TextStyle(fontSize: 11)),
                    trailing: Icon(Icons.chevron_right, size: 16),
                    onTap: () => _showIssueDetails(issue),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildResolvedIssuesBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RESOLVED ISSUES', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${_resolvedIssues.length} TOTAL', style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: _resolvedIssues.isEmpty 
            ? const Center(child: Text('No resolved issues yet.'))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _resolvedIssues.length.clamp(0, 5),
                separatorBuilder: (_, __) => Divider(),
                itemBuilder: (ctx, i) {
                  final issue = _resolvedIssues[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(issue.categoryEmoji, style: TextStyle(fontSize: 20)),
                    title: Text(issue.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('By ${issue.userName} · ${issue.locationName ?? "Unknown location"}', style: TextStyle(fontSize: 11)),
                    trailing: Icon(Icons.chevron_right, size: 16),
                    onTap: () => _showIssueDetails(issue),
                  );
                },
              ),
        ),
      ],
    );
  }

  void _showIssueDetails(CivicReport issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(issue.categoryEmoji, style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Expanded(child: Text(issue.title, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20))),
              ],
            ),
            SizedBox(height: 16),
            _detailRow('Status', issue.statusLabel, color: issue.status == ReportStatus.resolved ? Colors.green : Colors.orange),
            _detailRow('Reporter', issue.userName),
            _detailRow('Location', issue.locationName ?? 'Not specified'),
            _detailRow('Coordinates', '${issue.latitude}, ${issue.longitude}'),
            if (issue.description != null) ...[
              SizedBox(height: 12),
              Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(issue.description!, style: TextStyle(fontSize: 13, height: 1.5)),
            ],
            SizedBox(height: 24),
            Row(
              children: [
                if (issue.status != ReportStatus.resolved)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await context.read<ReportService>().updateReportStatus(issue.id, ReportStatus.resolved);
                        Navigator.pop(ctx);
                        _loadData();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text('MARK RESOLVED'),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await context.read<ReportService>().updateReportStatus(issue.id, ReportStatus.in_progress);
                        Navigator.pop(ctx);
                        _loadData();
                      },
                      child: Text('MOVE TO PENDING'),
                    ),
                  ),
                SizedBox(width: 12),
                if (issue.status != ReportStatus.resolved)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await context.read<ReportService>().updateReportStatus(issue.id, ReportStatus.rejected);
                        Navigator.pop(ctx);
                        _loadData();
                      },
                      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red)),
                      child: Text('REJECT', style: TextStyle(color: Colors.red)),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('CLOSE'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDim)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildPendingReviewsBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PENDING REVIEWS', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${_pendingReviews.length} WAITING', style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
          ],
        ),
        SizedBox(height: 12),
        if (_pendingReviews.isEmpty)
          Text('No submissions to review.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingReviews.length.clamp(0, 3),
            itemBuilder: (ctx, i) => _VerificationItem(
              submission: _pendingReviews[i],
              onApprove: () => _reviewSubmission(_pendingReviews[i].id, true),
              onReject: () => _reviewSubmission(_pendingReviews[i].id, false),
            ),
          ),
      ],
    );
  }

  Widget _buildChallengesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ACTIVE CHALLENGES', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: Icon(Icons.add_circle, color: AppTheme.primaryMagenta), onPressed: () => _showCreateForm(context)),
          ],
        ),
        SizedBox(height: 12),
        ..._activeChallenges.map((c) => _AdminChallengeItem(
          challenge: c,
          onEdit: () => _showCreateForm(context, existing: c),
          onTap: () => _showChallengeDetails(c),
        )),
      ],
    );
  }

  void _showChallengeDetails(Challenge c) async {
    // Fetch top contributors
    final client = Supabase.instance.client;
    final subsRaw = await client.from('submissions')
      .select('user_id, user_name')
      .eq('challenge_id', c.id)
      .eq('status', 'approved');
    
    final Map<String, int> counts = {};
    final Map<String, String> names = {};
    for (var s in (subsRaw as List)) {
      final uid = s['user_id'];
      counts[uid] = (counts[uid] ?? 0) + 1;
      names[uid] = s['user_name'];
    }
    final sortedUids = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.title.toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 24)),
              SizedBox(height: 8),
              Text('Artist / Creator: ${c.artistName ?? "Unknown"}', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMagenta)),
              SizedBox(height: 20),
              
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    _detailRow('Category', c.category.name.toUpperCase()),
                    _detailRow('City', c.city),
                    _detailRow('Progress', '${c.currentCount} / ${c.targetCount}'),
                    _detailRow('Points Reward', '${c.pointsReward} PTS'),
                    _detailRow('Created By', c.creatorName),
                    _detailRow('End Date', DateFormat.yMMMd().format(c.endDate)),
                  ],
                ),
              ),
              SizedBox(height: 20),

              if (c.description != null && c.description!.isNotEmpty) ...[
                Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1, color: AppTheme.textDim)),
                SizedBox(height: 6),
                Text(c.description!, style: GoogleFonts.inter(fontSize: 13, height: 1.5)),
                SizedBox(height: 16),
              ],
              
              if (c.missionBriefing.isNotEmpty) ...[
                Text('MISSION BRIEFING', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1, color: AppTheme.textDim)),
                SizedBox(height: 6),
                Text(c.missionBriefing, style: GoogleFonts.inter(fontSize: 13, height: 1.5)),
                SizedBox(height: 24),
              ],

              Text('TOP CONTRIBUTORS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1, color: AppTheme.textDim)),
              SizedBox(height: 12),
              if (sortedUids.isEmpty)
                Text('No approved submissions yet.', style: TextStyle(fontSize: 13))
              else
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedUids.length.clamp(0, 5),
                    separatorBuilder: (_, __) => Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2), height: 1),
                    itemBuilder: (ctx, i) {
                      final uid = sortedUids[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryMagenta.withOpacity(0.1),
                          child: Text('${i+1}', style: TextStyle(color: AppTheme.primaryMagenta, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(names[uid]!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        trailing: Text('${counts[uid]} subs', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMagenta, fontSize: 13)),
                      );
                    },
                  ),
                ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text('CLOSE')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reviewSubmission(String id, bool approve) async {
    final svc = context.read<SubmissionService>();
    if (approve) await svc.approveSubmission(id);
    else await svc.rejectSubmission(id);
    _loadData();
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDim,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationItem extends StatelessWidget {
  final Submission submission;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _VerificationItem({required this.submission, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(submission.imageUrl, width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.image, size: 40)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BY ${submission.userName.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      if (submission.caption != null) Text(submission.caption!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: onReject, child: Text('REJECT', style: TextStyle(fontSize: 11)))),
                SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: onApprove, child: Text('APPROVE', style: TextStyle(fontSize: 11)))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminChallengeItem extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const _AdminChallengeItem({required this.challenge, this.onEdit, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        title: Text(challenge.title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Artist: ${challenge.artistName ?? "Unknown"} · ${challenge.city}', style: TextStyle(fontSize: 11)),
        trailing: onEdit != null ? IconButton(icon: Icon(Icons.edit, size: 20), onPressed: onEdit) : null,
      ),
    );
  }
}

class _AdminDataExport extends StatelessWidget {
  const _AdminDataExport();

  Future<void> _exportData(BuildContext context, String table) async {
    try {
      final response = await Supabase.instance.client.from(table).select();
      if (response.isEmpty) return;

      final headers = (response.first as Map<String, dynamic>).keys.join(',');
      final rows = response.map((row) => (row as Map<String, dynamic>).values.map((v) => '"${v.toString().replaceAll('"', '""')}"').join(',')).join('\n');
      downloadCsv('${table}_export.csv', '$headers\n$rows');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _expBtn(context, 'DOWNLOAD CITIZEN PROFILES', Icons.people, 'profiles'),
        SizedBox(height: 8),
        _expBtn(context, 'DOWNLOAD ALL CHALLENGES', Icons.flash_on, 'challenges'),
      ],
    );
  }

  Widget _expBtn(BuildContext context, String label, IconData icon, String table) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _exportData(context, table),
        icon: Icon(icon, size: 16),
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _emailCtrl, decoration: InputDecoration(labelText: 'Email Address')),
            SizedBox(height: 12),
            DropdownButtonFormField<UserRole>(
              value: _selectedRole,
              items: [
                DropdownMenuItem(value: UserRole.admin, child: Text('ADMIN')),
                DropdownMenuItem(value: UserRole.creator, child: Text('CREATOR')),
              ],
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  setState(() => _isLoading = true);
                  try {
                    await context.read<AuthService>().assignRoleByEmail(_emailCtrl.text.trim(), _selectedRole);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role assigned!')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                  setState(() => _isLoading = false);
                },
                child: Text('ASSIGN ROLE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminEventsSection extends StatefulWidget {
  final AppUser user;
  const _AdminEventsSection({required this.user});
  @override
  State<_AdminEventsSection> createState() => _AdminEventsSectionState();
}

class _AdminEventsSectionState extends State<_AdminEventsSection> {
  final _svc = EventService();
  List<Event> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final events = await _svc.getAllEvents();
      if (mounted) setState(() { _events = events; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteEvent(String id) async {
    try {
      await _svc.deleteEvent(id);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('EVENTS', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: Icon(Icons.add_circle, color: AppTheme.primaryMagenta), 
              onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, 
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (_) => _EventForm(user: widget.user, onSaved: _load))),
          ],
        ),
        SizedBox(height: 12),
        if (_loading) const Center(child: CircularProgressIndicator())
        else ..._events.map((e) => Card(
          child: ListTile(
            title: Text(e.title, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${e.location} · ${e.slotsSold}/${e.totalSlots} slots'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 20),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                    builder: (_) => _EventForm(user: widget.user, existing: e, onSaved: _load),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Delete Event?'),
                        content: Text('This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('CANCEL')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: Text('DELETE', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) _deleteEvent(e.id);
                  },
                ),
                IconButton(icon: Icon(Icons.qr_code_scanner, size: 20), 
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GateCheckScreen(user: widget.user)))),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

class _EventForm extends StatefulWidget {
  final AppUser user;
  final Event? existing;
  final VoidCallback onSaved;
  const _EventForm({required this.user, this.existing, required this.onSaved});
  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _slotsCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  String? _selectedImageUrl;
  bool _saving = false;
  List<PriceTier> _tiers = [const PriceTier(label: 'General', pricePaise: 0)];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!.title;
      _descCtrl.text = widget.existing!.description ?? '';
      _locationCtrl.text = widget.existing!.location;
      _slotsCtrl.text = '${widget.existing!.totalSlots}';
      _date = widget.existing!.eventDate;
      _selectedImageUrl = widget.existing!.bannerUrl;
      _tiers = widget.existing!.priceTiers.toList();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _addTier() {
    final labelCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('Add Tier', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelCtrl, decoration: InputDecoration(labelText: 'Tier Name (e.g. VIP)')),
            SizedBox(height: 12),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Price (INR)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final priceInr = double.tryParse(priceCtrl.text) ?? 0;
              setState(() {
                _tiers.add(PriceTier(label: labelCtrl.text.trim(), pricePaise: (priceInr * 100).toInt()));
              });
              Navigator.pop(ctx);
            },
            child: Text('ADD'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('EVENT DETAILS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22)),
          SizedBox(height: 20),
          _FormField(controller: _titleCtrl, label: 'TITLE'),
          SizedBox(height: 12),
          _FormField(controller: _descCtrl, label: 'DESCRIPTION', maxLines: 3),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _FormField(controller: _locationCtrl, label: 'LOCATION')),
              SizedBox(width: 12),
              Expanded(child: _FormField(controller: _slotsCtrl, label: 'SLOTS', keyboardType: TextInputType.number)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DATE: ${DateFormat('MMM d, yyyy').format(_date)}', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, fontSize: 12)),
              TextButton(onPressed: _pickDate, child: Text('CHANGE')),
            ],
          ),
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PRICE TIERS', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, fontSize: 12)),
              TextButton(onPressed: _addTier, child: Text('+ ADD TIER')),
            ],
          ),
          ..._tiers.asMap().entries.map((e) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(e.value.label, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(e.value.formattedPrice),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle, color: Colors.red, size: 20),
                  onPressed: () => setState(() => _tiers.removeAt(e.key)),
                ),
              )),
          Divider(height: 24),
          Text('MEDIA UPLOAD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ChallengeImagePicker(
            initialImageUrl: _selectedImageUrl,
            onUploaded: (url) => _selectedImageUrl = url,
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : () async {
                setState(() => _saving = true);
                try {
                  final svc = EventService();
                  if (widget.existing != null) {
                    await svc.updateEvent(widget.existing!.id, {
                      'title': _titleCtrl.text, 
                      'description': _descCtrl.text,
                      'location': _locationCtrl.text, 
                      'event_date': _date.toUtc().toIso8601String(),
                      'total_slots': int.tryParse(_slotsCtrl.text) ?? 100,
                      'price_tiers': _tiers.map((t) => t.toMap()).toList(),
                      if (_selectedImageUrl != null) 'banner_url': _selectedImageUrl,
                    });
                  } else {
                    await svc.createEvent(
                      title: _titleCtrl.text,
                      description: _descCtrl.text,
                      location: _locationCtrl.text,
                      eventDate: _date,
                      totalSlots: int.tryParse(_slotsCtrl.text) ?? 100,
                      priceTiers: _tiers.isEmpty ? [const PriceTier(label: 'General', pricePaise: 0)] : _tiers,
                      createdBy: widget.user.id,
                      bannerUrl: _selectedImageUrl,
                    );
                  }
                  widget.onSaved();
                  Navigator.pop(context);
                } catch (e) {}
                setState(() => _saving = false);
              },
              child: Text(
                widget.existing == null ? 'CREATE EVENT →' : 'SAVE CHANGES →',
                style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
              ),
            ),
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
  const _FormField({required this.controller, required this.label, this.maxLines = 1, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.spaceMono(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryMagenta)),
        SizedBox(height: 6),
        TextField(
          controller: controller, 
          maxLines: maxLines, 
          keyboardType: keyboardType, 
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppTheme.primaryMagenta, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// Helper to hold tier form state
class _TierEntry {
  final TextEditingController labelCtrl;
  final TextEditingController paiseCtrl;

  _TierEntry({String label = 'General', int paise = 0})
      : labelCtrl = TextEditingController(text: label),
        paiseCtrl = TextEditingController(text: paise == 0 ? '0' : '$paise');
}
