import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/models/challenge.dart';
import 'package:social_code/models/submission.dart';
import 'package:social_code/services/submission_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminChallengeSubmissionsScreen extends StatefulWidget {
  final Challenge challenge;
  const AdminChallengeSubmissionsScreen({super.key, required this.challenge});

  @override
  State<AdminChallengeSubmissionsScreen> createState() => _AdminChallengeSubmissionsScreenState();
}

class _AdminChallengeSubmissionsScreenState extends State<AdminChallengeSubmissionsScreen> {
  List<Submission>? _submissions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    final subs = await context.read<SubmissionService>().getSubmissionsForChallenge(widget.challenge.id);
    if (mounted) {
      setState(() {
        _submissions = subs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SUBMISSIONS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
            Text(widget.challenge.title, style: const TextStyle(fontSize: 12, color: AppTheme.primaryMagenta, fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: AppTheme.primaryMagenta),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryMagenta))
          : _submissions == null || _submissions!.isEmpty
              ? Center(
                  child: Text('NO SUBMISSIONS YET',
                      style: GoogleFonts.spaceMono(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.bold)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _submissions!.length,
                  itemBuilder: (context, index) {
                    final sub = _submissions![index];
                    return _AdminSubmissionCard(submission: sub);
                  },
                ),
    );
  }
}

class _AdminSubmissionCard extends StatelessWidget {
  final Submission submission;
  const _AdminSubmissionCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(submission.imageUrl, fit: BoxFit.cover),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: submission.status == SubmissionStatus.approved 
                          ? Colors.green.withOpacity(0.9)
                          : submission.status == SubmissionStatus.rejected
                              ? Colors.red.withOpacity(0.9)
                              : Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      submission.status.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(submission.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                if (submission.caption != null && submission.caption!.isNotEmpty)
                  Text(submission.caption!, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
