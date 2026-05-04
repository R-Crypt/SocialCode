import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/models/app_user.dart';
import 'package:social_code/features/auth/screens/profile_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _citizens = [];
  List<Map<String, dynamic>> _creators = [];
  int _tabIndex = 0; // 0 = Citizens, 1 = Creators

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, email, display_name, role, points, region, profile_image_url, bio, instagram_url, website_url, creator_details')
          .order('points', ascending: false);

      final citizens = <Map<String, dynamic>>[];
      final creators = <Map<String, dynamic>>[];

      for (var u in response) {
        if (u['role'] == 'creator') {
          creators.add(u);
        } else if (u['role'] == 'citizen') {
          citizens.add(u);
        }
      }

      if (mounted) {
        setState(() {
          _citizens = citizens;
          _creators = creators;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        title: Text(
          'USER DIRECTORY',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: AppTheme.borderBlack,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryMagenta))
          : Column(
              children: [
                // Custom brutalist tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _tabIndex = 0),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: _tabIndex == 0
                                  ? AppTheme.primaryMagenta
                                  : Colors.white,
                              border: Border.all(
                                  color: AppTheme.borderBlack, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'CITIZENS (${_citizens.length})',
                              style: GoogleFonts.spaceMono(
                                fontWeight: FontWeight.bold,
                                color: _tabIndex == 0
                                    ? Colors.white
                                    : AppTheme.borderBlack,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _tabIndex = 1),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: _tabIndex == 1
                                  ? AppTheme.accentPurple
                                  : Colors.white,
                              border: Border.all(
                                  color: AppTheme.borderBlack, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'CREATORS (${_creators.length})',
                              style: GoogleFonts.spaceMono(
                                fontWeight: FontWeight.bold,
                                color: _tabIndex == 1
                                    ? Colors.white
                                    : AppTheme.borderBlack,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: _tabIndex == 0
                          ? _citizens.length
                          : _creators.length,
                      itemBuilder: (context, index) {
                        final user = _tabIndex == 0
                            ? _citizens[index]
                            : _creators[index];
                        final name = user['display_name'] ?? 'Unknown';
                        final email = user['email'] ?? '';
                        final pts = user['points'] ?? 0;
                        final region = user['region'] ?? 'Unknown';
                        final img = user['profile_image_url'];

                        return GestureDetector(
                          onTap: () {
                            final appUser = AppUser.fromMap(user, user['id']);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(user: appUser),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: AppTheme.borderBlack, width: 2),
                            ),
                            child: Row(
                              children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: _tabIndex == 0
                                    ? AppTheme.primaryMagenta.withOpacity(0.1)
                                    : AppTheme.accentPurple.withOpacity(0.1),
                                backgroundImage:
                                    img != null ? NetworkImage(img) : null,
                                child: img == null
                                    ? Text(
                                        name[0].toString().toUpperCase(),
                                        style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w900,
                                            color: _tabIndex == 0
                                                ? AppTheme.primaryMagenta
                                                : AppTheme.accentPurple),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.toString().toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      email,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.borderBlack
                                              .withOpacity(0.5)),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            size: 12,
                                            color: AppTheme.borderBlack
                                                .withOpacity(0.5)),
                                        const SizedBox(width: 4),
                                        Text(
                                          region,
                                          style: GoogleFonts.spaceMono(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.borderBlack
                                                  .withOpacity(0.5)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$pts',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: _tabIndex == 0
                                          ? AppTheme.primaryMagenta
                                          : AppTheme.accentPurple,
                                    ),
                                  ),
                                  Text(
                                    'PTS',
                                    style: GoogleFonts.spaceMono(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
