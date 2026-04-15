import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../core/theme/app_theme.dart';
import '../challenges/screens/challenges_list_screen.dart';
import '../stats/screens/leaderboard_screen.dart';
import '../panels/creator_panel.dart';
import '../panels/admin_panel.dart';
import '../../features/reporting/screens/civic_reporter_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const ChallengesListScreen(),
      const CivicReporterScreen(),
      const LeaderboardScreen(),
      if (widget.user.role == UserRole.creator) const CreatorPanel()
      else if (widget.user.role == UserRole.admin) const AdminPanel()
      else const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: AppTheme.backgroundDark,
          selectedItemColor: AppTheme.neonGreen,
          unselectedItemColor: Colors.white30,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'CODES'),
            const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'MAP'),
            const BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'LEADERBOARD'),
            BottomNavigationBarItem(
              icon: Icon(
                widget.user.role == UserRole.creator 
                  ? Icons.add_box 
                  : widget.user.role == UserRole.admin 
                    ? Icons.dashboard 
                    : Icons.person
              ),
              label: widget.user.role == UserRole.creator 
                ? 'CREATE' 
                : widget.user.role == UserRole.admin 
                  ? 'ADMIN' 
                  : 'ME',
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Profile Screen'));
}
