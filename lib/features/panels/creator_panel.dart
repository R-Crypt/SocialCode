import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class CreatorPanel extends StatelessWidget {
  const CreatorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CREATOR HUB',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.black,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Build your legacy. Spark the movement.',
                style: GoogleFonts.inter(color: Colors.white54),
              ),
              const SizedBox(height: 32),

              // Quick Stats Row
              Row(
                children: [
                  _buildStatCard('MY CODES', '12', AppTheme.primaryPurple),
                  const SizedBox(width: 16),
                  _buildStatCard('TOTAL IMPACT', '1.2k', AppTheme.neonGreen),
                ],
              ),
              const SizedBox(height: 40),

              // Action Buttons
              _buildActionButton(
                context,
                'NEW IMPACT CHALLENGE',
                'Launch a monthly code for the city',
                Icons.add_circle,
                AppTheme.neonGreen,
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                context,
                'MANAGE SUBMISSIONS',
                'Verify proof from your followers',
                Icons.verified_user,
                Colors.white10,
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                context,
                'ANALYTICS & REACH',
                'See how your influence is growing',
                Icons.bar_chart,
                Colors.white10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.black, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, String subtitle, IconData icon, Color highlightColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: highlightColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: highlightColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white24),
        ],
      ),
    );
  }
}
