enum UserRole { citizen, creator, admin }

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final int points;
  final String region;
  final String? profileImageUrl;
  final String? bio;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.points = 0,
    this.region = 'Bengaluru',
    this.profileImageUrl,
    this.bio,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      displayName: data['display_name'] ?? data['displayName'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == (data['role'] ?? 'citizen'),
        orElse: () => UserRole.citizen,
      ),
      points: data['points'] ?? 0,
      region: data['region'] ?? 'Bengaluru',
      profileImageUrl: data['profile_image_url'] ?? data['profileImageUrl'],
      bio: data['bio'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'display_name': displayName,
      'role': role.name,
      'points': points,
      'region': region,
      'profile_image_url': profileImageUrl,
      'bio': bio,
    };
  }

  AppUser copyWith({
    String? displayName,
    UserRole? role,
    int? points,
    String? region,
    String? profileImageUrl,
    String? bio,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      points: points ?? this.points,
      region: region ?? this.region,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
    );
  }
}
