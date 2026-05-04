import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/features/challenges/bloc/challenges_bloc.dart';
import 'package:social_code/models/app_user.dart';
import 'package:social_code/models/challenge.dart';
import 'package:social_code/services/challenge_service.dart';
import 'submit_proof_screen.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;
  final AppUser user;
  const ChallengeDetailScreen({super.key, required this.challenge, required this.user});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  bool _hasJoined = false;
  bool _checkingJoin = true;
  int _participants = 0;

  @override
  void initState() {
    super.initState();
    _loadJoinStatus();
  }

  Future<void> _loadJoinStatus() async {
    final service = context.read<ChallengeService>();
    final joined = await service.hasJoined(widget.challenge.id, widget.user.id);
    final count = await service.getParticipantCount(widget.challenge.id);
    if (mounted) {
      setState(() {
        _hasJoined = joined;
        _participants = count;
        _checkingJoin = false;
      });
    }
  }

  Future<void> _toggleJoin() async {
    final service = context.read<ChallengeService>();
    if (_hasJoined) {
      await service.leaveChallenge(widget.challenge.id, widget.user.id);
      if (mounted) setState(() { _hasJoined = false; _participants--; });
    } else {
      context.read<ChallengesBloc>().add(JoinChallenge(widget.challenge.id, widget.user.id));
      await service.joinChallenge(widget.challenge.id, widget.user.id);
      if (mounted) setState(() { _hasJoined = true; _participants++; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Hero
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.borderBlack,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: challenge.imageUrl != null
                  ? ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.4),
                        BlendMode.darken,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: challenge.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(color: AppTheme.borderBlack),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags row
                  Wrap(
                    spacing: 8,
                    children: [
                      _Tag('${challenge.pointsReward} POINTS', AppTheme.primaryMagenta),
                      _Tag('${challenge.daysRemaining} DAYS LEFT', AppTheme.borderBlack),
                      _Tag(challenge.city.toUpperCase(), AppTheme.accentPurple),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    challenge.title.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                      color: AppTheme.borderBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'BY ${challenge.creatorName.toUpperCase()}',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: AppTheme.borderBlack.withOpacity(0.4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Progress
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderBlack, width: 2),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('MISSION PROGRESS',
                                style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.borderBlack.withOpacity(0.5))),
                            Text(
                              '${challenge.currentCount} / ${challenge.targetCount}',
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryMagenta),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: challenge.progressPercent,
                          minHeight: 8,
                          backgroundColor: AppTheme.borderBlack.withOpacity(0.1),
                          valueColor:
                              const AlwaysStoppedAnimation(AppTheme.primaryMagenta),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_participants CITIZENS JOINED',
                          style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.borderBlack.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mission briefing
                  Text(
                    'MISSION BRIEFING',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppTheme.accentPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    challenge.missionBriefing.isNotEmpty
                        ? challenge.missionBriefing
                        : challenge.description,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppTheme.borderBlack.withOpacity(0.8),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Actions
                  if (!_checkingJoin) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _toggleJoin,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _hasJoined
                                ? AppTheme.borderBlack.withOpacity(0.3)
                                : AppTheme.primaryMagenta,
                            width: 2,
                          ),
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                        ),
                        child: Text(
                          _hasJoined ? '✓ JOINED — LEAVE MISSION' : 'JOIN THIS MISSION',
                          style: GoogleFonts.spaceMono(
                            fontWeight: FontWeight.bold,
                            color: _hasJoined
                                ? AppTheme.borderBlack.withOpacity(0.4)
                                : AppTheme.primaryMagenta,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubmitProofScreen(
                              challenge: challenge,
                              user: widget.user,
                            ),
                          ),
                        ),
                        child: const Text('SUBMIT PROOF →'),
                      ),
                    ),
                  ] else
                    const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryMagenta)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}
