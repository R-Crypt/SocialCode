import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/core/widgets/brutalist_widgets.dart';
import 'package:social_code/features/auth/bloc/auth_bloc.dart';
import 'package:social_code/features/challenges/bloc/challenges_bloc.dart';
import 'package:social_code/models/app_user.dart';
import 'package:social_code/models/challenge.dart';
import 'challenge_detail_screen.dart';

class ChallengesListScreen extends StatefulWidget {
  final AppUser user;
  const ChallengesListScreen({super.key, required this.user});

  @override
  State<ChallengesListScreen> createState() => _ChallengesListScreenState();
}

class _ChallengesListScreenState extends State<ChallengesListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChallengesBloc>().add(LoadChallenges());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            floating: true,
            pinned: true,
            backgroundColor: AppTheme.backgroundLight,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: AppTheme.borderBlack),
                onPressed: () => _confirmLogout(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              title: const SocialCodeLogo(fontSize: 22),
              centerTitle: false,
            ),
          ),

          // Greeting banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'HEY ${widget.user.displayName.toUpperCase().split(' ')[0]},\nOWN THE DAY.',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        color: AppTheme.borderBlack,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMagenta,
                      border: Border.all(color: AppTheme.borderBlack, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${widget.user.points}',
                          style: GoogleFonts.spaceMono(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'PTS',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          BlocBuilder<ChallengesBloc, ChallengesState>(
            builder: (context, state) {
              if (state is ChallengesLoading || state is ChallengesInitial) {
                return SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => _ShimmerCard(),
                      childCount: 3,
                    ),
                  ),
                );
              }

              if (state is ChallengesError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off,
                            size: 48, color: AppTheme.borderBlack),
                        const SizedBox(height: 16),
                        Text(
                          'COULD NOT LOAD CHALLENGES',
                          style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<ChallengesBloc>().add(LoadChallenges()),
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is ChallengesLoaded) {
                if (state.challenges.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text('NO ACTIVE CHALLENGES RIGHT NOW.\nCHECK BACK SOON.'),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ChallengeCard(
                        challenge: state.challenges[index],
                        user: widget.user,
                      ),
                      childCount: state.challenges.length,
                    ),
                  ),
                );
              }

              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('LOG OUT?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );
  }
}

// ignore_for_file: must_be_immutable
class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final AppUser user;

  const _ChallengeCard({required this.challenge, required this.user});

  String get _categoryLabel {
    switch (challenge.category) {
      case ChallengeCategory.environment:
        return '🌿 ENVIRONMENT';
      case ChallengeCategory.community:
        return '🤝 COMMUNITY';
      case ChallengeCategory.education:
        return '📚 EDUCATION';
      case ChallengeCategory.health:
        return '❤️ HEALTH';
      case ChallengeCategory.civic:
        return '🏙️ CIVIC';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderBlack, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image
          if (challenge.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: challenge.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.borderBlack.withOpacity(0.05),
                  child: const Icon(Icons.image_not_supported, size: 48),
                ),
              ),
            ),

          // Data table
          Table(
            border: TableBorder.all(color: AppTheme.borderBlack, width: 1.5),
            children: [
              TableRow(children: [
                BrutalistDataCell(label: 'CODE', value: challenge.title),
                BrutalistDataCell(
                    label: 'PTS', value: '${challenge.pointsReward}'),
              ]),
              TableRow(children: [
                TableCell(
                  child: MissionBar(
                    label: 'CATEGORY',
                    value: _categoryLabel,
                  ),
                ),
                const TableCell(child: SizedBox.shrink()),
              ]),
              TableRow(children: [
                BrutalistDataCell(
                    label: 'CITY', value: challenge.city.toUpperCase()),
                BrutalistDataCell(
                    label: 'DAYS LEFT',
                    value: '${challenge.daysRemaining}'),
              ]),
            ],
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MISSION PROGRESS',
                      style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.borderBlack.withOpacity(0.5)),
                    ),
                    Text(
                      '${challenge.currentCount} / ${challenge.targetCount}',
                      style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryMagenta),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: LinearProgressIndicator(
                    value: challenge.progressPercent,
                    minHeight: 6,
                    backgroundColor: AppTheme.borderBlack.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primaryMagenta),
                  ),
                ),
              ],
            ),
          ),

          // CTA
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChallengeDetailScreen(
                  challenge: challenge,
                  user: user,
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: AppTheme.borderBlack,
              child: Center(
                child: Text(
                  'VIEW MISSION BRIEFING →',
                  style: GoogleFonts.spaceMono(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        height: 280,
        color: Colors.white,
      ),
    );
  }
}
