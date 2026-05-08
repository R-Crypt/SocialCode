import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/models/app_user.dart';

class SettingsScreen extends StatelessWidget {
  final AppUser user;
  const SettingsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SETTINGS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('APPEARANCE', 
              style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryMagenta)),
          const SizedBox(height: 16),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.themeMode,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppTheme.primaryMagenta),
                        const SizedBox(width: 12),
                        Text('DARK THEME', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Switch(
                      value: isDark,
                      activeColor: AppTheme.primaryMagenta,
                      onChanged: (val) {
                        AppTheme.themeMode.value = val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text('NOTIFICATIONS', 
              style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryMagenta)),
          const SizedBox(height: 16),
          _SettingsTile(
            label: 'PUSH NOTIFICATIONS',
            icon: Icons.notifications_active_outlined,
            trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppTheme.primaryMagenta),
          ),
          const SizedBox(height: 32),
          Text('LEGAL', 
              style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryMagenta)),
          const SizedBox(height: 16),
          const _SettingsTile(label: 'PRIVACY POLICY', icon: Icons.description_outlined),
          const SizedBox(height: 8),
          const _SettingsTile(label: 'TERMS OF SERVICE', icon: Icons.gavel_outlined),
          const SizedBox(height: 8),
          const _SettingsTile(label: 'DATA ERASURE (GDPR)', icon: Icons.delete_outline, color: Colors.red),
          
          const SizedBox(height: 48),
          Center(
            child: Text('VERSION 1.0.0 (BETA)', 
                style: GoogleFonts.spaceMono(fontSize: 10, color: AppTheme.textDim)),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget? trailing;
  final Color? color;

  const _SettingsTile({required this.label, required this.icon, this.trailing, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurface, size: 20),
              const SizedBox(width: 12),
              Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color ?? Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          if (trailing != null) trailing! else Icon(Icons.chevron_right, size: 20, color: Theme.of(context).colorScheme.onSurface),
        ],
      ),
    );
  }
}
