enum SubmissionStatus { pending, approved, rejected }

class Submission {
  final String id;
  final String challengeId;
  final String userId;
  final String userName;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;
  final SubmissionStatus status;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final int pointsAwarded;
  final String? reviewerNotes;

  Submission({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.imageUrl,
    this.caption,
    required this.createdAt,
    this.status = SubmissionStatus.pending,
    this.latitude,
    this.longitude,
    this.locationName,
    this.pointsAwarded = 0,
    this.reviewerNotes,
  });

  factory Submission.fromMap(Map<String, dynamic> data, String id) {
    return Submission(
      id: id,
      challengeId: data['challenge_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? 'Anonymous',
      imageUrl: data['image_url'] ?? '',
      caption: data['caption'],
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      status: SubmissionStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => SubmissionStatus.pending,
      ),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      locationName: data['location_name'],
      pointsAwarded: data['points_awarded'] ?? 0,
      reviewerNotes: data['reviewer_notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challenge_id': challengeId,
      'user_id': userId,
      'user_name': userName,
      'image_url': imageUrl,
      'caption': caption,
      'status': status.name,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'points_awarded': pointsAwarded,
      'reviewer_notes': reviewerNotes,
    };
  }
}
