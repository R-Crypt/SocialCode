import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:social_code/core/theme/app_theme.dart';

class SocialCodeLogo extends StatelessWidget {
  final double fontSize;
  final bool showTagline;
  final Color? color;
  final CrossAxisAlignment crossAxisAlignment;

  const SocialCodeLogo({
    super.key,
    this.fontSize = 28,
    this.showTagline = true,
    this.color,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final baseStyle = GoogleFonts.outfit(
      fontWeight: FontWeight.w900,
      fontSize: fontSize,
      letterSpacing: -1.0,
    );

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            // Shadow text
            Transform.translate(
              offset: const Offset(4, 4),
              child: Text(
                'SOCIAL CODE',
                style: baseStyle.copyWith(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.black,
                ),
              ),
            ),
            // Gradient text
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: isDark 
                   ? [const Color(0xFFF48FB1), const Color(0xFFCE93D8)] // Lighter pink/purple for dark mode
                   : [const Color(0xFFE91E63), const Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'SOCIAL CODE',
                style: baseStyle.copyWith(color: Colors.white), // Color must be white for ShaderMask to work fully
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          SizedBox(height: 4),
          Text(
            'GOOD IS THE NEW FLEX',
            style: GoogleFonts.spaceMono(
              fontSize: fontSize * 0.3,
              fontWeight: FontWeight.bold,
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.onSurface).withOpacity(0.5),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ],
    );
  }
}
