import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:social_code/core/theme/app_theme.dart';

class BrutalistDataCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? backgroundColor;
  final Color? textColor;

  const BrutalistDataCell({
    super.key,
    required this.label,
    required this.value,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        border: Border.all(color: AppTheme.textMain, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label :',
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: textColor ?? AppTheme.textMain,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value.toUpperCase(),
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: textColor ?? AppTheme.textMain,
            ),
          ),
        ],
      ),
    );
  }
}

class MissionBar extends StatelessWidget {
  final String label;
  final String value;

  const MissionBar({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryMagenta,
        border: Border.all(color: AppTheme.textMain, width: 1.5),
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Colors.white,
            ),
            children: [
              TextSpan(text: '$label : '),
              TextSpan(
                text: value.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LogInfoCard extends StatelessWidget {
  final String label;
  final String content;

  const LogInfoCard({
    super.key,
    required this.label,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.textMain, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppTheme.textMain.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppTheme.textMain),
          const SizedBox(height: 8),
          Text(
            content.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppTheme.textMain,
            ),
          ),
        ],
      ),
    );
  }
}

class SocialCodeLogo extends StatelessWidget {
  final double fontSize;
  const SocialCodeLogo({super.key, this.fontSize = 48});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [AppTheme.primaryMagenta, AppTheme.accentPurple],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        'SOCIAL CODE',
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 0.9,
          shadows: [
            const Shadow(
              offset: Offset(2, 2),
              blurRadius: 0,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}
