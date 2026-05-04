enum ChallengeStatus { active, upcoming, completed, draft, pending }
enum ChallengeCategory { environment, community, education, health, civic }

class Challenge {
  final String id;
  final String title;
  final String description;
  final String missionBriefing;
  final String? creatorId;
  final String creatorName;
  final DateTime startDate;
  final DateTime endDate;
  final int pointsReward;
  final ChallengeStatus status;
  final String? imageUrl;
  final ChallengeCategory category;
  final String city;
  final int targetCount;
  final int currentCount;
  final DateTime createdAt;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    this.missionBriefing = '',
    this.creatorId,
    required this.creatorName,
    required this.startDate,
    required this.endDate,
    required this.pointsReward,
    this.status = ChallengeStatus.active,
    this.imageUrl,
    this.category = ChallengeCategory.environment,
    this.city = 'Bengaluru',
    this.targetCount = 100,
    this.currentCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Challenge.fromMap(Map<String, dynamic> data, String id) {
    return Challenge(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      missionBriefing: data['mission_briefing'] ?? '',
      creatorId: data['creator_id'],
      creatorName: data['creator_name'] ?? 'Admin',
      startDate: DateTime.parse(data['start_date']),
      endDate: DateTime.parse(data['end_date']),
      pointsReward: data['points_reward'] ?? 0,
      status: ChallengeStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'active'),
        orElse: () => ChallengeStatus.active,
      ),
      imageUrl: data['image_url'],
      category: ChallengeCategory.values.firstWhere(
        (e) => e.name == (data['category'] ?? 'environment'),
        orElse: () => ChallengeCategory.environment,
      ),
      city: data['city'] ?? 'Bengaluru',
      targetCount: data['target_count'] ?? 100,
      currentCount: data['current_count'] ?? 0,
      createdAt: data['created_at'] != null ? DateTime.parse(data['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'mission_briefing': missionBriefing,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'points_reward': pointsReward,
      'status': status.name,
      'image_url': imageUrl,
      'category': category.name,
      'city': city,
      'target_count': targetCount,
      'current_count': currentCount,
    };
  }

  /// Days remaining
  int get daysRemaining {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Progress percentage 0.0 to 1.0
  double get progressPercent {
    if (targetCount == 0) return 0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }
}
