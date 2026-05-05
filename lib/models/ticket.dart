import 'package:intl/intl.dart';

enum TicketStatus { valid, used, cancelled, expired }

class Ticket {
  final String id;
  final String eventId;
  final String? userId;

  // PII — maskable under DPDPA Right to Erasure
  final String attendeeName;
  final String attendeeEmail;
  final String? attendeePhone;

  // Payment
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final int amountPaidPaise;
  final String priceTierLabel;

  // QR — HMAC-SHA256 derived, globally unique
  final String qrToken;

  // Lifecycle
  final TicketStatus status;
  final DateTime? scannedAt;
  final String? scannedBy;

  // DPDPA
  final bool isPiiErased;
  final DateTime createdAt;

  const Ticket({
    required this.id,
    required this.eventId,
    this.userId,
    required this.attendeeName,
    required this.attendeeEmail,
    this.attendeePhone,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.amountPaidPaise,
    required this.priceTierLabel,
    required this.qrToken,
    required this.status,
    this.scannedAt,
    this.scannedBy,
    required this.isPiiErased,
    required this.createdAt,
  });

  double get amountPaidInr => amountPaidPaise / 100.0;
  bool get isFree => amountPaidPaise == 0;
  String get formattedAmount =>
      isFree ? 'FREE' : '₹${NumberFormat('#,##0').format(amountPaidInr)}';

  factory Ticket.fromMap(Map<String, dynamic> map) => Ticket(
        id: map['id'] as String,
        eventId: map['event_id'] as String,
        userId: map['user_id'] as String?,
        attendeeName: map['attendee_name'] as String? ?? '[ERASED]',
        attendeeEmail: map['attendee_email'] as String? ?? '[ERASED]',
        attendeePhone: map['attendee_phone'] as String?,
        razorpayOrderId: map['razorpay_order_id'] as String?,
        razorpayPaymentId: map['razorpay_payment_id'] as String?,
        amountPaidPaise: map['amount_paid_paise'] as int? ?? 0,
        priceTierLabel: map['price_tier_label'] as String? ?? 'General',
        qrToken: map['qr_token'] as String,
        status: TicketStatus.values.firstWhere(
          (s) => s.name == (map['status'] as String? ?? 'valid'),
          orElse: () => TicketStatus.valid,
        ),
        scannedAt: map['scanned_at'] != null
            ? DateTime.parse(map['scanned_at'] as String)
            : null,
        scannedBy: map['scanned_by'] as String?,
        isPiiErased: map['is_pii_erased'] as bool? ?? false,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
