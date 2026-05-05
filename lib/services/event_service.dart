import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_code/models/event.dart';

class EventService {
  SupabaseClient get _client => Supabase.instance.client;

  // ─── Fetch all published events ──────────────────────────────────────────
  Future<List<Event>> getPublishedEvents() async {
    final data = await _client
        .from('events')
        .select()
        .eq('status', 'published')
        .order('event_date', ascending: true);
    return (data as List).map((m) => Event.fromMap(m)).toList();
  }

  // ─── Fetch all events (admin) ─────────────────────────────────────────────
  Future<List<Event>> getAllEvents() async {
    final data = await _client
        .from('events')
        .select()
        .order('event_date', ascending: false);
    return (data as List).map((m) => Event.fromMap(m)).toList();
  }

  // ─── Fetch single event ───────────────────────────────────────────────────
  Future<Event?> getEventById(String eventId) async {
    final data = await _client
        .from('events')
        .select()
        .eq('id', eventId)
        .maybeSingle();
    return data == null ? null : Event.fromMap(data);
  }

  // ─── Admin: Create event ──────────────────────────────────────────────────
  /// RLS enforces admin-only INSERT; throws PostgrestException if not admin.
  Future<Event> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required int totalSlots,
    required List<PriceTier> priceTiers,
    String? bannerUrl,
    EventStatus status = EventStatus.published,
    required String createdBy,
  }) async {
    final payload = {
      'title': title.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'event_date': eventDate.toUtc().toIso8601String(),
      'total_slots': totalSlots,
      'price_tiers': priceTiers.map((t) => t.toMap()).toList(),
      if (bannerUrl != null) 'banner_url': bannerUrl,
      'status': status.name,
      'created_by': createdBy,
    };

    final result = await _client
        .from('events')
        .insert(payload)
        .select()
        .single();

    return Event.fromMap(result);
  }

  // ─── Admin: Update event ──────────────────────────────────────────────────
  Future<Event> updateEvent(
    String eventId,
    Map<String, dynamic> updates,
  ) async {
    final result = await _client
        .from('events')
        .update(updates)
        .eq('id', eventId)
        .select()
        .single();
    return Event.fromMap(result);
  }

  // ─── Admin: Delete event ──────────────────────────────────────────────────
  Future<void> deleteEvent(String eventId) async {
    await _client.from('events').delete().eq('id', eventId);
  }

  // ─── Create Razorpay order via Supabase Edge Function ────────────────────
  /// Calls the `create-razorpay-order` Edge Function.
  /// Returns the Razorpay order object or throws.
  Future<Map<String, dynamic>> createRazorpayOrder({
    required String eventId,
    required String userId,
    required String attendeeName,
    required String attendeeEmail,
    required String tierLabel,
    required int amountPaise,
    String policyVersion = 'v1.0',
  }) async {
    final response = await _client.functions.invoke(
      'create-razorpay-order',
      body: {
        'event_id': eventId,
        'user_id': userId,
        'attendee_name': attendeeName,
        'attendee_email': attendeeEmail,
        'tier_label': tierLabel,
        'amount_paise': amountPaise,
        'policy_version': policyVersion,
      },
    );

    if (response.status != 200) {
      final err = response.data?['error'] ?? 'Order creation failed';
      throw Exception(err);
    }
    return Map<String, dynamic>.from(response.data as Map);
  }
}
