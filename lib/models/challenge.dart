enum ChallengeStatus { active, upcoming, completed }

class Challenge {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String creatorName;
  final DateTime startDate;
  final DateTime endDate;
  final int pointsReward;
  final ChallengeStatus status;
  final String? imageUrl;
  final List<String> participants;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.startDate,
    required this.endDate,
    required this.pointsReward,
    this.status = ChallengeStatus.active,
    this.imageUrl,
    this.participants = const [],
  });

  factory Challenge.fromMap(Map<String, dynamic> data, String id) {
    return Challenge(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? 'Admin',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      pointsReward: data['pointsReward'] ?? 0,
      status: ChallengeStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'active'),
        orElse: () => ChallengeStatus.active,
      ),
      imageUrl: data['imageUrl'],
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'pointsReward': pointsReward,
      'status': status.name,
      'imageUrl': imageUrl,
      'participants': participants,
    };
  }
}
