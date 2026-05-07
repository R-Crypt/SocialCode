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
    final effectiveColor = color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textMain);

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SOCIAL CODE',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
            color: effectiveColor,
            letterSpacing: -0.5,
          ),
        ),
        if (showTagline)
          Text(
            'GOOD IS THE NEW FLEX',
            style: GoogleFonts.spaceMono(
              fontSize: fontSize * 0.3,
              fontWeight: FontWeight.bold,
              color: effectiveColor.withOpacity(0.5),
              letterSpacing: 1.0,
            ),
          ),
      ],
    );
  }
}
