import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'submit_proof_screen.dart';

class ChallengeDetailScreen extends StatelessWidget {
  const ChallengeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          // Hero Image
          Container(
            height: 350,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=1000'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    AppTheme.backgroundDark,
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                        ),
                        child: Text(
                          '80 POINTS',
                          style: GoogleFonts.outfit(
                            color: AppTheme.neonGreen,
                            fontWeight: FontWeight.black,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('•  Ends in 12 days', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'STREET GREEN\nCHALLENGE',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      height: 0.9,
                      fontWeight: FontWeight.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MISSION BRIEFING',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bangalore is losing its green cover. We need citizens to act. Find a spot in your neighborhood, plant a native sapling, and care for it. This isn’t just a photo op—it’s a commitment.',
                    style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  ),
                  const Spacer(),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SubmitProofScreen()),
                        );
                      },
                      child: const Text('JOIN MISSION & SUBMIT PROOF'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
