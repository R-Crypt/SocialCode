enum UserRole { citizen, creator, admin }

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final int points;
  final String? region;
  final String? profileImageUrl;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.points = 0,
    this.region,
    this.profileImageUrl,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == (data['role'] ?? 'citizen'),
        orElse: () => UserRole.citizen,
      ),
      points: data['points'] ?? 0,
      region: data['region'],
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'points': points,
      'region': region,
      'profileImageUrl': profileImageUrl,
    };
  }
}
