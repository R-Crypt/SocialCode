import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_code/models/challenge.dart';

class ChallengeService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Fetch all active/upcoming challenges
  Future<List<Challenge>> getChallenges({
    String? status,
    String? category,
    String? city,
  }) async {
    var query = _client.from('challenges').select();
    if (status != null) {
      query = query.eq('status', status) as dynamic;
    }
    if (category != null) {
      query = query.eq('category', category) as dynamic;
    }
    if (city != null) {
      query = query.eq('city', city) as dynamic;
    }
    final response = await _client
        .from('challenges')
        .select()
        .inFilter('status', status != null ? [status] : ['active', 'upcoming'])
        .order('created_at', ascending: false);

    return (response as List)
        .map((data) => Challenge.fromMap(data as Map<String, dynamic>, data['id']))
        .toList();
  }

  /// Get a single challenge by id
  Future<Challenge?> getChallenge(String id) async {
    final response = await _client
        .from('challenges')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Challenge.fromMap(response, response['id']);
  }

  /// Create a new challenge (creator/admin only)
  Future<Challenge> createChallenge(Challenge challenge) async {
    final data = challenge.toMap();
    final response = await _client
        .from('challenges')
        .insert(data)
        .select()
        .single();
    return Challenge.fromMap(response, response['id']);
  }

  /// Update a challenge
  Future<void> updateChallenge(String id, Map<String, dynamic> updates) async {
    await _client.from('challenges').update(updates).eq('id', id);
  }

  /// Delete a challenge (admin only)
  Future<void> deleteChallenge(String id) async {
    await _client.from('challenges').delete().eq('id', id);
  }

  /// Join a challenge
  Future<void> joinChallenge(String challengeId, String userId) async {
    await _client.from('challenge_participants').upsert({
      'challenge_id': challengeId,
      'user_id': userId,
    });
  }

  /// Leave a challenge
  Future<void> leaveChallenge(String challengeId, String userId) async {
    await _client
        .from('challenge_participants')
        .delete()
        .eq('challenge_id', challengeId)
        .eq('user_id', userId);
  }

  /// Check if user has joined
  Future<bool> hasJoined(String challengeId, String userId) async {
    final response = await _client
        .from('challenge_participants')
        .select()
        .eq('challenge_id', challengeId)
        .eq('user_id', userId)
        .maybeSingle();
    return response != null;
  }

  /// Get participant count
  Future<int> getParticipantCount(String challengeId) async {
    final response = await _client
        .from('challenge_participants')
        .select()
        .eq('challenge_id', challengeId);
    return (response as List).length;
  }

  /// Real-time stream of challenges
  Stream<List<Challenge>> watchChallenges() {
    return _client
        .from('challenges')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data
            .where((d) => d['status'] == 'active' || d['status'] == 'upcoming')
            .map((d) => Challenge.fromMap(d, d['id']))
            .toList());
  }
}
