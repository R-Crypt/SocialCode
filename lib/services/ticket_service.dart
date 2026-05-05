import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_code/models/ticket.dart';

class TicketService {
  SupabaseClient get _client => Supabase.instance.client;

  // ─── My tickets ──────────────────────────────────────────────────────────
  Future<List<Ticket>> getMyTickets() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final data = await _client
        .from('tickets')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return (data as List).map((m) => Ticket.fromMap(m)).toList();
  }

  // ─── Tickets for an event (admin) ────────────────────────────────────────
  Future<List<Ticket>> getTicketsForEvent(String eventId) async {
    final data = await _client
        .from('tickets')
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false);
    return (data as List).map((m) => Ticket.fromMap(m)).toList();
  }

  // ─── Gate Check: verify QR token ─────────────────────────────────────────
  /// Calls the DB function which atomically validates and marks the ticket used.
  /// Returns a result map with keys: success, message, attendee_name, event_title.
  Future<Map<String, dynamic>> verifyAndUseTicket(String qrToken) async {
    final user = _client.auth.currentUser;
    final response = await _client.rpc('verify_and_use_ticket', params: {
      'p_qr_token': qrToken,
      'p_scanned_by': user?.id,
    });

    final rows = response as List;
    if (rows.isEmpty) {
      return {'success': false, 'message': 'No result from server'};
    }
    return Map<String, dynamic>.from(rows.first as Map);
  }

  // ─── Admin: cancel a ticket ───────────────────────────────────────────────
  Future<void> cancelTicket(String ticketId) async {
    await _client
        .from('tickets')
        .update({'status': 'cancelled'})
        .eq('id', ticketId);
  }
}
