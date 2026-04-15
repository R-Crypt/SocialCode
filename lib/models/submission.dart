import 'package:cloud_firestore/cloud_firestore.dart';

enum SubmissionStatus { pending, approved, rejected }

class Submission {
  final String id;
  final String challengeId;
  final String userId;
  final String userName;
  final String imageUrl;
  final String? caption;
  final DateTime timestamp;
  final SubmissionStatus status;
  final double? latitude;
  final double? longitude;

  Submission({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.imageUrl,
    this.caption,
    required this.timestamp,
    this.status = SubmissionStatus.pending,
    this.latitude,
    this.longitude,
  });

  factory Submission.fromMap(Map<String, dynamic> data, String id) {
    return Submission(
      id: id,
      challengeId: data['challengeId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: SubmissionStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => SubmissionStatus.pending,
      ),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'userId': userId,
      'userName': userName,
      'imageUrl': imageUrl,
      'caption': caption,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
