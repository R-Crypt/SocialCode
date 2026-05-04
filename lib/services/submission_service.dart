import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_code/models/submission.dart';

class SubmissionService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Upload image bytes to Supabase Storage and return public URL
  Future<String> uploadProofImage(Uint8List imageBytes, String userId) async {
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storagePath = 'submissions/$fileName';

    await _client.storage.from('submissions').uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    final publicUrl = _client.storage.from('submissions').getPublicUrl(storagePath);
    return publicUrl;
  }

  /// Submit proof for a challenge
  Future<Submission> submitProof({
    required String challengeId,
    required String userId,
    required String userName,
    required Uint8List imageBytes,
    String? caption,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    // Upload image first
    final imageUrl = await uploadProofImage(imageBytes, userId);

    final data = {
      'challenge_id': challengeId,
      'user_id': userId,
      'user_name': userName,
      'image_url': imageUrl,
      'caption': caption,
      'status': 'pending',
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
    };

    final response = await _client
        .from('submissions')
        .insert(data)
        .select()
        .single();

    return Submission.fromMap(response, response['id']);
  }

  /// Get submissions for a challenge
  Future<List<Submission>> getSubmissionsForChallenge(String challengeId) async {
    final response = await _client
        .from('submissions')
        .select()
        .eq('challenge_id', challengeId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((d) => Submission.fromMap(d as Map<String, dynamic>, d['id']))
        .toList();
  }

  /// Get a user's submissions
  Future<List<Submission>> getUserSubmissions(String userId) async {
    final response = await _client
        .from('submissions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((d) => Submission.fromMap(d as Map<String, dynamic>, d['id']))
        .toList();
  }

  /// Get all pending submissions (admin/creator)
  Future<List<Submission>> getPendingSubmissions() async {
    final response = await _client
        .from('submissions')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (response as List)
        .map((d) => Submission.fromMap(d as Map<String, dynamic>, d['id']))
        .toList();
  }

  /// Approve a submission
  Future<void> approveSubmission(String submissionId, {String? notes}) async {
    await _client.from('submissions').update({
      'status': 'approved',
      'reviewer_notes': notes,
    }).eq('id', submissionId);
  }

  /// Reject a submission
  Future<void> rejectSubmission(String submissionId, {String? notes}) async {
    await _client.from('submissions').update({
      'status': 'rejected',
      'reviewer_notes': notes,
    }).eq('id', submissionId);
  }

  /// Stream of pending submissions (for admin real-time updates)
  Stream<List<Submission>> watchPendingSubmissions() {
    return _client
        .from('submissions')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .map((data) => data
            .map((d) => Submission.fromMap(d, d['id']))
            .toList());
  }
}
