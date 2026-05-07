enum ReportCategory { pothole, waste, streetlight, water, tree, noise, safety, misc }
enum ReportStatus { reported, in_progress, resolved, rejected }

class CivicReport {
  final String id;
  final String? userId;
  final String userName;
  final String title;
  final String? description;
  final ReportCategory category;
  final ReportStatus status;
  final double latitude;
  final double longitude;
  final String? locationName;
  final String? imageUrl;
  final int upvotes;
  final DateTime createdAt;

  CivicReport({
    required this.id,
    this.userId,
    required this.userName,
    required this.title,
    this.description,
    required this.category,
    this.status = ReportStatus.reported,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.imageUrl,
    this.upvotes = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CivicReport.fromMap(Map<String, dynamic> data, String id) {
    return CivicReport(
      id: id,
      userId: data['user_id'],
      userName: data['user_name'] ?? 'Anonymous',
      title: data['title'] ?? '',
      description: data['description'],
      category: ReportCategory.values.firstWhere(
        (e) => e.name == (data['category'] ?? 'misc'),
        orElse: () => ReportCategory.misc,
      ),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'reported').replaceAll('_', '_'),
        orElse: () => ReportStatus.reported,
      ),
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      locationName: data['location_name'],
      imageUrl: data['image_url'],
      upvotes: data['upvotes'] ?? 0,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'title': title,
      'description': description,
      'category': category.name,
      'status': status.name,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'image_url': imageUrl,
      'upvotes': upvotes,
    };
  }

  String get categoryEmoji {
    switch (category) {
      case ReportCategory.pothole: return '🕳️';
      case ReportCategory.waste: return '🗑️';
      case ReportCategory.streetlight: return '💡';
      case ReportCategory.water: return '💧';
      case ReportCategory.tree: return '🌳';
      case ReportCategory.noise: return '🔊';
      case ReportCategory.safety: return '🛡️';
      case ReportCategory.misc: return '⚠️';
    }
  }

  String get statusLabel {
    switch (status) {
      case ReportStatus.reported: return 'REPORTED';
      case ReportStatus.in_progress: return 'IN PROGRESS';
      case ReportStatus.resolved: return 'RESOLVED';
      case ReportStatus.rejected: return 'REJECTED';
    }
  }
}
