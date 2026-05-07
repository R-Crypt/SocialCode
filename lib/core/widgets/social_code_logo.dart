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
    final logoWidget = Text(
      'SOCIAL CODE',
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w900,
        fontSize: fontSize,
        letterSpacing: -1.0,
        shadows: [
          const Shadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: logoWidget,
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'GOOD IS THE NEW FLEX',
            style: GoogleFonts.spaceMono(
              fontSize: fontSize * 0.3,
              fontWeight: FontWeight.bold,
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textMain).withOpacity(0.5),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ],
    );
  }
}
