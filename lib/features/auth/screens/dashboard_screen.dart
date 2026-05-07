import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:social_code/models/app_user.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/features/auth/bloc/auth_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_code/features/challenges/screens/challenges_list_screen.dart';
import 'package:social_code/features/stats/screens/leaderboard_screen.dart';
import 'package:social_code/features/panels/creator_panel.dart';
import 'package:social_code/features/panels/admin_panel.dart';
import 'package:social_code/features/reporting/screens/civic_reporter_screen.dart';
import 'package:social_code/features/auth/screens/profile_screen.dart';
import 'package:social_code/features/events/screens/events_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    try {
      final res = await Supabase.instance.client
          .from('user_consents')
          .select()
          .eq('user_id', widget.user.id)
          .maybeSingle();

      if (res == null) {
        if (mounted) {
          _showConsentBanner();
        }
      }
    } catch (e) {
      // Handle error gracefully or retry
    }
  }

  void _showConsentBanner() {
    bool analytics = true;
    bool marketing = true;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => PopScope(
          canPop: false, // Prevent back button
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR DATA. YOUR RULES.', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 24)),
                const SizedBox(height: 8),
                Text('SocialCode requires basic cookies to function. We also use optional cookies for analytics and marketing.', style: GoogleFonts.inter(fontSize: 14)),
                const SizedBox(height: 24),
                CheckboxListTile(
                  value: true,
                  onChanged: null,
                  activeColor: AppTheme.textMain,
                  title: Text('ESSENTIAL (REQUIRED)', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, fontSize: 12)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: analytics,
                  onChanged: (val) => setState(() => analytics = val ?? false),
                  activeColor: AppTheme.primaryMagenta,
                  title: Text('ANALYTICS & PERFORMANCE', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, fontSize: 12)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: marketing,
                  onChanged: (val) => setState(() => marketing = val ?? false),
                  activeColor: AppTheme.primaryMagenta,
                  title: Text('MARKETING & OFFERS', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, fontSize: 12)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppTheme.textMain, width: 2),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: () => _saveConsent(false, false),
                        child: Text('REJECT ALL', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryMagenta,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: () => _saveConsent(analytics, marketing),
                        child: Text('ACCEPT', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveConsent(bool analytics, bool marketing) async {
    try {
      await Supabase.instance.client.from('user_consents').insert({
        'user_id': widget.user.id,
        'analytics_consent': analytics,
        'marketing_consent': marketing,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save preferences.')));
      }
    }
  }

  List<_NavItem> get _navItems {
    final baseTabs = [
      const _NavItem(icon: Icons.flash_on, label: 'CODES'),
      const _NavItem(icon: Icons.map, label: 'MAP'),
      const _NavItem(icon: Icons.emoji_events, label: 'STATS'),
      const _NavItem(icon: Icons.event, label: 'EVENTS'),
    ];

    if (widget.user.role == UserRole.creator) {
      baseTabs.add(const _NavItem(icon: Icons.add_box, label: 'CREATE'));
    } else if (widget.user.role == UserRole.admin) {
      baseTabs.add(const _NavItem(icon: Icons.dashboard_customize, label: 'ADMIN'));
    }

    baseTabs.add(const _NavItem(icon: Icons.person, label: 'ME'));
    return baseTabs;
  }

  Widget get _currentScreen {
    switch (_selectedIndex) {
      case 0:
        return ChallengesListScreen(user: widget.user);
      case 1:
        return CivicReporterScreen(user: widget.user);
      case 2:
        return const LeaderboardScreen();
      case 3:
        return EventsListScreen(user: widget.user);
      case 4:
        if (widget.user.role == UserRole.creator) {
          return CreatorPanel(user: widget.user);
        } else if (widget.user.role == UserRole.admin) {
          return AdminPanel(
            user: widget.user,
            onNavigateToCodes: () => setState(() => _selectedIndex = 0),
          );
        }
        return ProfileScreen(user: widget.user); // Citizen
      case 5:
        return ProfileScreen(user: widget.user); // Creator/Admin
      default:
        return ChallengesListScreen(user: widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        if (isWide) {
          // TABLET / DESKTOP: Side navigation rail
          return Scaffold(
            body: Row(
              children: [
                _SideNav(
                  items: _navItems,
                  selectedIndex: _selectedIndex,
                  user: widget.user,
                  onTap: (i) => setState(() => _selectedIndex = i),
                ),
                const VerticalDivider(width: 1, thickness: 2, color: AppTheme.textMain),
                Expanded(child: _currentScreen),
              ],
            ),
          );
        }

        // MOBILE: Bottom nav
        return Scaffold(
          body: _currentScreen,
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.textMain, width: 2)),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
              backgroundColor: Colors.white,
              selectedItemColor: AppTheme.primaryMagenta,
              unselectedItemColor: AppTheme.textMain,
              showUnselectedLabels: true,
              selectedLabelStyle: GoogleFonts.spaceMono(
                fontWeight: FontWeight.w900,
                fontSize: 9,
              ),
              unselectedLabelStyle: GoogleFonts.spaceMono(fontSize: 9),
              type: BottomNavigationBarType.fixed,
              items: _navItems
                  .map((item) => BottomNavigationBarItem(
                        icon: Icon(item.icon),
                        label: item.label,
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _SideNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final AppUser user;
  final ValueChanged<int> onTap;

  const _SideNav({
    required this.items,
    required this.selectedIndex,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppTheme.primaryMagenta, AppTheme.accentPurple],
                    ).createShader(bounds),
                    child: Text(
                      'SOCIAL\nCODE',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 0.9,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GOOD IS THE NEW FLEX',
                    style: GoogleFonts.spaceMono(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 2, color: AppTheme.textMain),
            const SizedBox(height: 16),

            // Nav items
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = selectedIndex == i;
              return GestureDetector(
                onTap: () => onTap(i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryMagenta
                        : Colors.transparent,
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textMain.withOpacity(0.6),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.label,
                        style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textMain.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const Spacer(),
            const Divider(height: 1, thickness: 2, color: AppTheme.textMain),

            // User + logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryMagenta.withOpacity(0.1),
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryMagenta,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${user.points} PTS',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: AppTheme.primaryMagenta,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 18),
                    onPressed: () =>
                        context.read<AuthBloc>().add(LogoutRequested()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
