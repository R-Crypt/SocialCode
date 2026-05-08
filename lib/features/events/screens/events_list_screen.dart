import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/models/event.dart';
import 'package:social_code/models/app_user.dart';
import 'package:social_code/services/event_service.dart';
import 'package:social_code/features/events/screens/event_detail_screen.dart';

class EventsListScreen extends StatefulWidget {
  final AppUser user;
  const EventsListScreen({super.key, required this.user});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final _service = EventService();
  List<Event> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final events = await _service.getPublishedEvents();
      if (mounted) setState(() { _events = events; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        title: Text('EVENTS',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900, fontSize: 22, color: Theme.of(context).colorScheme.onSurface)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryMagenta))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : _events.isEmpty
                  ? _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primaryMagenta,
                      child: ListView.builder(
                        padding: EdgeInsets.all(20),
                        itemCount: _events.length,
                        itemBuilder: (ctx, i) => _EventCard(
                          event: _events[i],
                          user: widget.user,
                        ),
                      ),
                    ),
    );
  }
}

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final Event event;
  final AppUser user;
  const _EventCard({required this.event, required this.user});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy • HH:mm').format(event.eventDate.toLocal());
    final slotsColor = event.isSoldOut
        ? Colors.red
        : event.slotsRemaining < 20
            ? Colors.orange
            : Colors.green;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, user: user)),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          boxShadow: [BoxShadow(color: Color(0xFF111111), offset: Offset(4, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            if (event.bannerUrl != null)
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Image.network(
                  event.bannerUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _BannerPlaceholder(),
                ),
              )
            else
              _BannerPlaceholder(),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status chips row
                  Row(
                    children: [
                      _Chip(
                        label: event.isFree ? 'FREE' : event.priceTiers.first.formattedPrice,
                        color: event.isFree ? Colors.green : AppTheme.primaryMagenta,
                      ),
                      SizedBox(width: 8),
                      _Chip(
                        label: event.isSoldOut
                            ? 'SOLD OUT'
                            : '${event.slotsRemaining} LEFT',
                        color: slotsColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  Text(event.title.toUpperCase(),
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900, fontSize: 18)),
                  SizedBox(height: 6),

                  Row(children: [
                    Icon(Icons.calendar_today, size: 12, color: AppTheme.primaryMagenta),
                    SizedBox(width: 4),
                    Text(dateStr,
                        style: GoogleFonts.spaceMono(
                            fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  ]),
                  SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on, size: 12, color: AppTheme.primaryMagenta),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(event.location,
                          style: GoogleFonts.spaceMono(
                              fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),

                  if (event.description != null) ...[
                    SizedBox(height: 10),
                    Text(event.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  ],

                  SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: event.isSoldOut
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => EventDetailScreen(event: event, user: user)),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: event.isSoldOut ? Colors.grey : Theme.of(context).colorScheme.onSurface,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text(
                        event.isSoldOut ? 'SOLD OUT' : event.isFree ? 'REGISTER FREE →' : 'GET TICKET →',
                        style: GoogleFonts.spaceMono(
                            fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: color,
      child: Text(label,
          style: GoogleFonts.spaceMono(
              fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 120,
        color: AppTheme.primaryMagenta.withOpacity(0.08),
        child: Center(
          child: Icon(Icons.event, size: 48, color: AppTheme.primaryMagenta.withOpacity(0.3)),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red),
            SizedBox(height: 8),
            Text('Failed to load events', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            TextButton(onPressed: onRetry, child: Text('RETRY')),
          ],
        ),
      );
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 56, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15)),
            SizedBox(height: 12),
            Text('NO EVENTS YET',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18)),
            SizedBox(height: 4),
            Text('Check back soon.',
                style: GoogleFonts.spaceMono(
                    fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
          ],
        ),
      );
}
