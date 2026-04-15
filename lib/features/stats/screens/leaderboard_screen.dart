import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // Spotlight Header (Top 3 Users)
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.backgroundDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.only(top: 100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildTopUser(context, 'Rohan', '2,450', 2, 80),
                    _buildTopUser(context, 'Aanya', '3,100', 1, 100),
                    _buildTopUser(context, 'Kabir', '2,100', 3, 70),
                  ],
                ),
              ),
              title: Text(
                'TOP FLEXERS',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.black,
                  fontSize: 20,
                  color: AppTheme.neonGreen,
                ),
              ),
              centerTitle: true,
            ),
          ),

          // Search / Filter Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'BANGALORE REGION',
                    style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.tune, color: Colors.white30, size: 20),
                ],
              ),
            ),
          ),

          // Leaderboard List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildRankItem(index + 4),
                childCount: 15, // More mock data
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUser(BuildContext context, String name, String points, int rank, double size) {
    final isWinner = rank == 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isWinner) const Icon(Icons.workspace_premium, color: AppTheme.neonGreen, size: 24),
        const SizedBox(height: 8),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isWinner ? AppTheme.neonGreen : Colors.white24,
              width: isWinner ? 3 : 1,
            ),
            image: const DecorationImage(
              image: NetworkImage('https://i.pravatar.cc/150'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          '$points PTS',
          style: GoogleFonts.outfit(
            color: isWinner ? AppTheme.neonGreen : Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.black,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRankItem(int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: GoogleFonts.outfit(
              color: Colors.white30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'User Name $rank',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${3000 - rank * 100} PTS',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
