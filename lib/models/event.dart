import 'package:intl/intl.dart';

// ─── Price Tier ──────────────────────────────────────────────────────────────

class PriceTier {
  final String label;
  final int pricePaise; // stored in paise (1 INR = 100 paise)

  const PriceTier({required this.label, required this.pricePaise});

  bool get isFree => pricePaise == 0;
  double get priceInr => pricePaise / 100.0;
  String get formattedPrice =>
      isFree ? 'FREE' : '₹${NumberFormat('#,##0').format(priceInr)}';

  factory PriceTier.fromMap(Map<String, dynamic> map) => PriceTier(
        label: map['label'] as String? ?? 'General',
        pricePaise: map['price_paise'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'label': label,
        'price_paise': pricePaise,
      };

  PriceTier copyWith({String? label, int? pricePaise}) => PriceTier(
        label: label ?? this.label,
        pricePaise: pricePaise ?? this.pricePaise,
      );
}

// ─── Event Status ────────────────────────────────────────────────────────────

enum EventStatus { draft, published, cancelled, completed }

// ─── Event Model ─────────────────────────────────────────────────────────────

class Event {
  final String id;
  final String title;
  final String? description;
  final String location;
  final DateTime eventDate;
  final int totalSlots;
  final int slotsSold;
  final List<PriceTier> priceTiers;
  final String? bannerUrl;
  final EventStatus status;
  final String? createdBy;
  final DateTime createdAt;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.location,
    required this.eventDate,
    required this.totalSlots,
    required this.slotsSold,
    required this.priceTiers,
    this.bannerUrl,
    required this.status,
    this.createdBy,
    required this.createdAt,
  });

  int get slotsRemaining => totalSlots - slotsSold;
  bool get isSoldOut => slotsRemaining <= 0;
  bool get isFree => priceTiers.isNotEmpty && priceTiers.first.isFree;
  bool get isPast => eventDate.isBefore(DateTime.now());

  factory Event.fromMap(Map<String, dynamic> map) {
    final tiersRaw = map['price_tiers'];
    final List<PriceTier> tiers = tiersRaw is List
        ? tiersRaw
            .map((t) => PriceTier.fromMap(Map<String, dynamic>.from(t as Map)))
            .toList()
        : [const PriceTier(label: 'General', pricePaise: 0)];

    return Event(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      location: map['location'] as String,
      eventDate: DateTime.parse(map['event_date'] as String),
      totalSlots: map['total_slots'] as int? ?? 100,
      slotsSold: map['slots_sold'] as int? ?? 0,
      priceTiers: tiers.isEmpty
          ? [const PriceTier(label: 'General', pricePaise: 0)]
          : tiers,
      bannerUrl: map['banner_url'] as String?,
      status: EventStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'published'),
        orElse: () => EventStatus.published,
      ),
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'title': title,
        'description': description,
        'location': location,
        'event_date': eventDate.toUtc().toIso8601String(),
        'total_slots': totalSlots,
        'price_tiers': priceTiers.map((t) => t.toMap()).toList(),
        if (bannerUrl != null) 'banner_url': bannerUrl,
        'status': status.name,
      };
}
