import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/features/challenges/bloc/challenges_bloc.dart';
import 'package:social_code/models/app_user.dart';
import 'package:social_code/models/challenge.dart';
import 'challenge_detail_screen.dart';
import 'package:social_code/core/widgets/social_code_logo.dart';
import 'package:social_code/services/submission_service.dart';
import 'package:social_code/services/auth_service.dart';
import 'package:social_code/features/auth/screens/settings_screen.dart';

class ChallengesListScreen extends StatefulWidget {
  final AppUser user;
  const ChallengesListScreen({super.key, required this.user});

  @override
  State<ChallengesListScreen> createState() => _ChallengesListScreenState();
}

class _ChallengesListScreenState extends State<ChallengesListScreen> {
  bool isGridView = true;
  String searchQuery = '';
  ChallengeCategory? selectedCategory;

  @override
  void initState() {
    super.initState();
    context.read<ChallengesBloc>().add(LoadChallenges());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndToggle(),
            _buildFilters(),
            Expanded(
              child: BlocBuilder<ChallengesBloc, ChallengesState>(
                builder: (context, state) {
                  if (state is ChallengesLoading || state is ChallengesInitial) {
                    return _buildLoading();
                  }
                  if (state is ChallengesError) {
                    return _buildError();
                  }
                  if (state is ChallengesLoaded) {
                    final filtered = state.challenges.where((c) {
                      final matchesSearch = c.title.toLowerCase().contains(searchQuery.toLowerCase());
                      final matchesCat = selectedCategory == null || c.category == selectedCategory;
                      return matchesSearch && matchesCat;
                    }).toList();

                    if (filtered.isEmpty) {
                      return _buildEmpty();
                    }

                    return isGridView 
                      ? _buildGridView(filtered) 
                      : _buildListView(filtered);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SocialCodeLogo(fontSize: 28),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.notifications_none_outlined), onPressed: () {}),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.user.profileImageUrl != null 
                  ? NetworkImage(widget.user.profileImageUrl!) 
                  : null,
                child: widget.user.profileImageUrl == null ? const Icon(Icons.person) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, size: 20, color: AppTheme.textDim.withOpacity(0.8)),
                  hintText: 'Search codes by name...',
                  hintStyle: TextStyle(color: AppTheme.textDim.withOpacity(0.8), fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: () {},
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_alt_outlined, color: AppTheme.primaryMagenta, size: 18),
            const SizedBox(width: 6),
            Text('Filter', style: GoogleFonts.outfit(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Row(
              children: [
                Expanded(child: _toggleButton(true, Icons.grid_view_rounded, 'Grid View')),
                Container(width: 1, height: 30, color: Theme.of(context).colorScheme.outline),
                Expanded(child: _toggleButton(false, Icons.list_rounded, 'List View')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _filterChip('Category', selectedCategory?.name ?? 'All', () => _showCategoryPicker()),
              const SizedBox(width: 8),
              _filterChip('City', 'All', () {}),
              const SizedBox(width: 8),
              _filterChip('Days Left', 'Any', () {}),
              const SizedBox(width: 8),
              _filterChip('Points', 'Any', () {}),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => setState(() { selectedCategory = null; searchQuery = ''; }),
                child: Row(
                  children: [
                    const Text('Reset', style: TextStyle(color: AppTheme.primaryMagenta, fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(Icons.refresh, size: 14, color: AppTheme.primaryMagenta),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _toggleButton(bool grid, IconData icon, String label) {
    final active = isGridView == grid;
    return GestureDetector(
      onTap: () => setState(() => isGridView = grid),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E24) : const Color(0xFF22252A)) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : AppTheme.textDim.withOpacity(0.8)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(color: active ? Colors.white : AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Text(label, style: GoogleFonts.outfit(color: AppTheme.textMain, fontSize: 13)),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textMain),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('All Categories'), onTap: () { setState(() => selectedCategory = null); Navigator.pop(context); }),
            ...ChallengeCategory.values.map((c) => ListTile(
              title: Text(c.name.toUpperCase()),
              onTap: () { setState(() => selectedCategory = c); Navigator.pop(context); },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<Challenge> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _ChallengeCard(challenge: items[i], user: widget.user, isGrid: true),
    );
  }

  Widget _buildListView(List<Challenge> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _ChallengeCard(challenge: items[i], user: widget.user, isGrid: false),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryMagenta));
  }

  Widget _buildError() {
    return Center(child: Text('Error loading challenges', style: GoogleFonts.outfit()));
  }

  Widget _buildEmpty() {
    return Center(child: Text('No challenges found', style: GoogleFonts.outfit()));
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final AppUser user;
  final bool isGrid;

  const _ChallengeCard({required this.challenge, required this.user, required this.isGrid});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChallengeDetailScreen(challenge: challenge, user: user)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: isGrid ? 1.4 : 16 / 9,
                  child: challenge.imageUrl != null 
                    ? CachedNetworkImage(imageUrl: challenge.imageUrl!, fit: BoxFit.cover)
                    : Container(color: Colors.grey[300]),
                ),
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    width: 42,
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMagenta.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${challenge.pointsReward}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        Text('PTS', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(challenge.category).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Text(challenge.category.name.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        const SizedBox(width: 4),
                        Icon(_getCategoryIcon(challenge.category), size: 12, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Expanded(
                         child: Text(challenge.title, 
                           maxLines: 1, overflow: TextOverflow.ellipsis,
                           style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                       ),
                       Icon(Icons.bookmark_outline, size: 20, color: Theme.of(context).colorScheme.onSurface),
                     ],
                   ),
                   if (challenge.artistName != null && challenge.artistName!.isNotEmpty)
                     Padding(
                       padding: const EdgeInsets.only(top: 2),
                       child: Text('BY ${challenge.artistName!.toUpperCase()}', 
                         style: const TextStyle(color: AppTheme.primaryMagenta, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                     ),
                   const SizedBox(height: 10),
                   Row(
                     children: [
                       const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textDim),
                       const SizedBox(width: 4),
                       Text(challenge.city, style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 11)),
                       const Padding(
                         padding: EdgeInsets.symmetric(horizontal: 6),
                         child: Icon(Icons.circle, size: 3, color: AppTheme.textDim),
                       ),
                       const Icon(Icons.access_time, size: 14, color: AppTheme.textDim),
                       const SizedBox(width: 4),
                       Text('${challenge.daysRemaining} days left', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 11)),
                     ],
                   ),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('PROGRESS', style: GoogleFonts.spaceMono(color: AppTheme.textDim, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                       Text('${challenge.currentCount} / ${challenge.targetCount}', 
                         style: GoogleFonts.spaceMono(color: AppTheme.primaryMagenta, fontSize: 10, fontWeight: FontWeight.bold)),
                     ],
                   ),
                   const SizedBox(height: 8),
                   ClipRRect(
                     borderRadius: BorderRadius.circular(100),
                     child: LinearProgressIndicator(
                       value: challenge.progressPercent,
                       minHeight: 6,
                       backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                       valueColor: AlwaysStoppedAnimation(_getCategoryColor(challenge.category)),
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(ChallengeCategory cat) {
    switch (cat) {
      case ChallengeCategory.environment: return const Color(0xFF4CAF50);
      case ChallengeCategory.community: return const Color(0xFF2196F3);
      case ChallengeCategory.education: return const Color(0xFF9C27B0);
      case ChallengeCategory.health: return const Color(0xFFFF5722);
      case ChallengeCategory.civic: return AppTheme.primaryMagenta;
    }
  }

  IconData _getCategoryIcon(ChallengeCategory cat) {
    switch (cat) {
      case ChallengeCategory.environment: return Icons.eco_rounded;
      case ChallengeCategory.community: return Icons.groups_rounded;
      case ChallengeCategory.education: return Icons.school_rounded;
      case ChallengeCategory.health: return Icons.favorite_rounded;
      case ChallengeCategory.civic: return Icons.location_city_rounded;
    }
  }
}
