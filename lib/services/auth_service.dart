import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:social_code/models/app_user.dart';

class AuthService {
  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  // Stream of current auth state
  Stream<sb.AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Current user (auth)
  sb.User? get currentAuthUser => _client.auth.currentUser;

  // --- EMAIL / PASSWORD ---

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<sb.AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
    UserRole role = UserRole.citizen,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName, 'role': role.name},
    );
    return response;
  }

  // --- GOOGLE SIGN IN ---

  static const String _webRedirectUrl = 'https://social-code.vercel.app';

  Future<void> signInWithGoogle() async {
    final redirectTo = kIsWeb
        ? _webRedirectUrl
        : 'io.supabase.socialcode://login-callback';
    await sb.Supabase.instance.client.auth.signInWithOAuth(
      sb.OAuthProvider.google,
      redirectTo: redirectTo,
      queryParams: {
        'prompt': 'consent',
      },
    );
  }

  // --- PROFILE ---

  Future<AppUser?> getCurrentUserData() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // Profile not yet created, create it now
        final displayName = user.userMetadata?['display_name'] as String? ??
            user.email?.split('@')[0] ??
            'Citizen';
        final newUser = AppUser(
          id: user.id,
          email: user.email ?? '',
          displayName: displayName,
          role: UserRole.citizen,
        );
        await _client.from('profiles').upsert({
          'id': user.id,
          ...newUser.toMap(),
        });
        return newUser;
      }

      return AppUser.fromMap(response, response['id']);
    } catch (e) {
      // Return a minimal user object from auth data on profile fetch failure
      return AppUser(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['display_name'] as String? ??
            user.email?.split('@')[0] ??
            'Citizen',
        role: UserRole.citizen,
      );
    }
  }

  Future<String> uploadAvatarImage(Uint8List imageBytes, String userId) async {
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storagePath = '$fileName';

    await _client.storage.from('avatars').uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: const sb.FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    return _client.storage.from('avatars').getPublicUrl(storagePath);
  }

  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? region,
    String? bio,
    String? profileImageUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (region != null) updates['region'] = region;
    if (bio != null) updates['bio'] = bio;
    if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;

    await _client.from('profiles').update(updates).eq('id', userId);
  }

  // --- ROLE MANAGEMENT (FOR DEMO/TESTING) ---
  
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    final roleString = newRole.name.toLowerCase();
    await _client.from('profiles').update({'role': roleString}).eq('id', userId);
  }

  Future<void> assignRoleByEmail(String email, UserRole newRole) async {
    final roleString = newRole.name.toLowerCase();
    final response = await _client.from('profiles').update({'role': roleString}).eq('email', email).select();
    if (response.isEmpty) {
      throw Exception('User with email $email not found.');
    }
  }

  // --- SIGN OUT ---

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
