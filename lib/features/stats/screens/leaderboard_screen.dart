import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/models/app_user.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _leaders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, display_name, profile_image_url, points, region, role')
          .inFilter('role', ['citizen', 'creator'])
          .order('points', ascending: false)
          .limit(50);
      if (mounted) {
        setState(() {
          _leaders = List<Map<String, dynamic>>.from(response);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Header podium
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppTheme.backgroundLight,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryMagenta))
                  : _leaders.isNotEmpty
                      ? _buildPodium()
                      : const SizedBox(),
              title: Text(
                'TOP CITIZENS',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppTheme.borderBlack),
              ),
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
            ),
          ),

          // Region label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Text(
                    'BENGALURU LEADERBOARD',
                    style: GoogleFonts.spaceMono(
                        color: AppTheme.borderBlack.withOpacity(0.4),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.2),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _loadLeaderboard,
                    child: const Icon(Icons.refresh, size: 18, color: AppTheme.primaryMagenta),
                  ),
                ],
              ),
            ),
          ),

          // Error
          if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Text('COULD NOT LOAD LEADERBOARD',
                      style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
                  ElevatedButton(
                      onPressed: _loadLeaderboard, child: const Text('RETRY')),
                ]),
              ),
            ),

          // List
          if (_loading)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      height: 60,
                      color: Colors.white,
                    ),
                  ),
                  childCount: 10,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (_leaders.isEmpty) {
                      return _buildEmptyState();
                    }
                    final item = _leaders[index + 3];
                    return _buildRankItem(item, index + 4);
                  },
                  childCount: _leaders.isEmpty
                      ? 1
                      : (_leaders.length > 3 ? _leaders.length - 3 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Text('NO USERS YET.\nBE THE FIRST TO FLEX.', textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildPodium() {
    final top3 = _leaders.take(3).toList();
    if (top3.isEmpty) return const SizedBox();

    final first = top3[0];
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null) _buildPodiumUser(second, 2, 70),
          _buildPodiumUser(first, 1, 90),
          if (third != null) _buildPodiumUser(third, 3, 60),
        ],
      ),
    );
  }

  Widget _buildPodiumUser(Map<String, dynamic> user, int rank, double size) {
    final isFirst = rank == 1;
    final name = (user['display_name'] as String? ?? 'User').toUpperCase();
    final pts = user['points'] as int? ?? 0;
    final imgUrl = user['profile_image_url'] as String?;
    
    final pedestalHeight = rank == 1 ? 140.0 : rank == 2 ? 100.0 : 80.0;
    final pedestalWidth = rank == 1 ? 110.0 : 90.0;
    final pedestalColor = rank == 1 ? AppTheme.primaryMagenta : Colors.white;
    final textColor = rank == 1 ? Colors.white : AppTheme.borderBlack;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFirst)
            const Icon(Icons.workspace_premium, color: AppTheme.primaryMagenta, size: 28),
          if (!isFirst) const SizedBox(height: 28),
          const SizedBox(height: 4),
          
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderBlack, width: 2),
            ),
            child: CircleAvatar(
              radius: size / 2,
              backgroundColor: AppTheme.primaryMagenta.withOpacity(0.1),
              backgroundImage: imgUrl != null ? NetworkImage(imgUrl) : null,
              child: imgUrl == null
                  ? Text(name[0],
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: size / 3,
                          color: AppTheme.primaryMagenta))
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          
          // Name
          Text(
            name.split(' ')[0],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.borderBlack),
          ),
          const SizedBox(height: 8),
          
          // Pedestal Block
          Container(
            height: pedestalHeight,
            width: pedestalWidth,
            decoration: BoxDecoration(
              color: pedestalColor,
              border: Border.all(color: AppTheme.borderBlack, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.borderBlack,
                  offset: Offset(4, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'RANK $rank',
                  style: GoogleFonts.spaceMono(
                    color: textColor.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pts',
                  style: GoogleFonts.outfit(
                    color: textColor,
                    fontSize: isFirst ? 24 : 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'PTS',
                  style: GoogleFonts.outfit(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankItem(Map<String, dynamic> user, int rank) {
    final name = user['display_name'] as String? ?? 'User';
    final pts = user['points'] as int? ?? 0;
    final imgUrl = user['profile_image_url'] as String?;
    final region = user['region'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderBlack, width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: GoogleFonts.spaceMono(
                  color: AppTheme.borderBlack.withOpacity(0.3),
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryMagenta.withOpacity(0.1),
            backgroundImage: imgUrl != null ? NetworkImage(imgUrl) : null,
            child: imgUrl == null
                ? Text(name[0].toUpperCase(),
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryMagenta))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (region.isNotEmpty)
                  Text(region,
                      style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.borderBlack.withOpacity(0.4))),
              ],
            ),
          ),
          Text(
            '$pts PTS',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                color: AppTheme.borderBlack.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
