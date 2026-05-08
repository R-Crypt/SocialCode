import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/models/event.dart';
import 'package:social_code/models/app_user.dart';
import 'package:social_code/models/ticket.dart';
import 'package:social_code/services/event_service.dart';
import 'package:social_code/services/ticket_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Payment flow:
/// (Payment is temporarily skipped. Direct ticket generation is used).

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final AppUser user;
  const EventDetailScreen({super.key, required this.event, required this.user});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  PriceTier? _selectedTier;
  bool _consentGiven = false;
  bool _loading = false;

  // After successful payment, poll for ticket
  Ticket? _ticket;
  bool _pollingForTicket = false;

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.event.priceTiers.first;
    _nameCtrl.text  = widget.user.displayName;
    _emailCtrl.text = widget.user.email;
    _checkExistingTicket();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // On open: check if user already holds a ticket for this event
  Future<void> _checkExistingTicket() async {
    try {
      final svc = TicketService();
      final myTickets = await svc.getMyTickets();
      final found = myTickets.where((t) => t.eventId == widget.event.id).firstOrNull;
      if (found != null && mounted) setState(() => _ticket = found);
    } catch (_) {}
  }

  Future<void> _proceedToPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the consent to continue.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final tier = _selectedTier!;
      
      // Directly insert ticket into DB to skip payment as requested
      final qrToken = 'QR_${DateTime.now().millisecondsSinceEpoch}_${widget.user.id.substring(0, 5)}';
      
      final response = await Supabase.instance.client.from('tickets').insert({
        'event_id': widget.event.id,
        'user_id': widget.user.id,
        'attendee_name': _nameCtrl.text.trim(),
        'attendee_email': _emailCtrl.text.trim(),
        'attendee_phone': _phoneCtrl.text.trim(),
        'amount_paid_paise': 0, // Mock as free
        'price_tier_label': tier.label,
        'qr_token': qrToken,
        'status': 'valid',
      }).select().single();
      
      if (mounted) {
        setState(() {
          _ticket = Ticket.fromMap(response);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Poll Supabase every 3 s (up to 10 attempts) after returning from payment
  Future<void> _pollForTicket() async {
    // This is no longer strictly needed since we skip payment, but kept just in case.
    if (_pollingForTicket) return;
    setState(() => _pollingForTicket = true);
    final svc = TicketService();
    for (var i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        final myTickets = await svc.getMyTickets();
        final found = myTickets.where((t) => t.eventId == widget.event.id).firstOrNull;
        if (found != null && mounted) {
          setState(() { _ticket = found; _pollingForTicket = false; });
          return;
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _pollingForTicket = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy • HH:mm').format(widget.event.eventDate.toLocal());

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: AppTheme.lightBg,
        elevation: 0,
        title: Text('EVENT DETAILS',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: AppTheme.textMain),
        ),
      ),
      body: _ticket != null ? _TicketView(ticket: _ticket!, event: widget.event) : _BookingView(
        event: widget.event,
        dateStr: dateStr,
        formKey: _formKey,
        nameCtrl: _nameCtrl,
        emailCtrl: _emailCtrl,
        phoneCtrl: _phoneCtrl,
        selectedTier: _selectedTier,
        onTierChanged: (t) => setState(() => _selectedTier = t),
        consentGiven: _consentGiven,
        onConsentChanged: (v) => setState(() => _consentGiven = v ?? false),
        loading: _loading,
        pollingForTicket: _pollingForTicket,
        onProceed: _proceedToPayment,
      ),
    );
  }
}

// ─── Booking Form View ────────────────────────────────────────────────────────

class _BookingView extends StatelessWidget {
  final Event event;
  final String dateStr;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, emailCtrl, phoneCtrl;
  final PriceTier? selectedTier;
  final ValueChanged<PriceTier?> onTierChanged;
  final bool consentGiven;
  final ValueChanged<bool?> onConsentChanged;
  final bool loading;
  final bool pollingForTicket;
  final VoidCallback onProceed;

  const _BookingView({
    required this.event, required this.dateStr, required this.formKey,
    required this.nameCtrl, required this.emailCtrl, required this.phoneCtrl,
    required this.selectedTier, required this.onTierChanged,
    required this.consentGiven, required this.onConsentChanged,
    required this.loading, required this.pollingForTicket, required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event header
            if (event.bannerUrl != null)
              ClipRect(
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.network(event.bannerUrl!, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 16),
            Text(event.title.toUpperCase(),
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22)),
            const SizedBox(height: 8),
            _InfoRow(Icons.calendar_today, dateStr),
            const SizedBox(height: 4),
            _InfoRow(Icons.location_on, event.location),
            const SizedBox(height: 4),
            _InfoRow(
              Icons.confirmation_number,
              event.isSoldOut
                  ? 'SOLD OUT'
                  : '${event.slotsRemaining} / ${event.totalSlots} slots remaining',
            ),
            if (event.description != null) ...[
              const SizedBox(height: 12),
              Text(event.description!,
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMain.withOpacity(0.7))),
            ],

            const SizedBox(height: 24),
            _SectionHeader('SELECT TIER'),
            const SizedBox(height: 10),
            ...event.priceTiers.map((tier) => _TierRadio(
                  tier: tier,
                  selected: selectedTier == tier,
                  onTap: () => onTierChanged(tier),
                )),

            const SizedBox(height: 24),
            _SectionHeader('ATTENDEE DETAILS'),
            const SizedBox(height: 10),
            _BrutalField(ctrl: nameCtrl,  label: 'FULL NAME',      hint: 'As on ID'),
            const SizedBox(height: 12),
            _BrutalField(ctrl: emailCtrl, label: 'EMAIL',          hint: 'Ticket sent here',
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _BrutalField(ctrl: phoneCtrl, label: 'PHONE (optional)', hint: '+91 XXXXXXXXXX',
                required: false, keyboardType: TextInputType.phone),

            const SizedBox(height: 20),
            // DPDPA Consent
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.textMain, width: 1.5),
                color: AppTheme.primaryMagenta.withOpacity(0.04),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: consentGiven,
                    onChanged: onConsentChanged,
                    activeColor: AppTheme.primaryMagenta,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'I consent to my personal data being processed for ticket issuance '
                      'and event entry verification under the Digital Personal Data '
                      'Protection Act 2023 (DPDPA). Policy v1.0.',
                      style: GoogleFonts.inter(fontSize: 12,
                          color: AppTheme.textMain.withOpacity(0.7)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            if (pollingForTicket)
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.accentPurple.withOpacity(0.08),
                child: Row(children: [
                  const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentPurple)),
                  const SizedBox(width: 12),
                  Text('Confirming payment & issuing ticket…',
                      style: GoogleFonts.spaceMono(fontSize: 11)),
                ]),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: event.isSoldOut || loading ? null : onProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMagenta,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          event.isSoldOut
                              ? 'SOLD OUT'
                              : selectedTier?.isFree == true
                                  ? 'REGISTER FREE →'
                                  : 'PAY ${selectedTier?.formattedPrice ?? ''} →',
                          style: GoogleFonts.spaceMono(
                              fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Ticket QR View ───────────────────────────────────────────────────────────

class _TicketView extends StatelessWidget {
  final Ticket ticket;
  final Event event;
  const _TicketView({required this.ticket, required this.event});

  @override
  Widget build(BuildContext context) {
    final statusColor = ticket.status == TicketStatus.valid
        ? Colors.green
        : ticket.status == TicketStatus.used
            ? Colors.orange
            : Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.textMain, width: 2),
              boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(6, 6))],
            ),
            child: Column(
              children: [
                Text('YOUR TICKET',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 4),
                Text(event.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 20),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(12),
                  color: AppTheme.lightBg,
                  child: ticket.status == TicketStatus.used
                      ? Column(children: [
                          const Icon(Icons.check_circle, size: 80, color: Colors.orange),
                          const SizedBox(height: 8),
                          Text('TICKET USED', style: GoogleFonts.outfit(fontWeight: FontWeight.w900,
                              fontSize: 16, color: Colors.orange)),
                        ])
                      : QrImageView(
                          data: ticket.qrToken,
                          version: QrVersions.auto,
                          size: 220,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppTheme.textMain,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppTheme.textMain,
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: statusColor,
                  child: Text(ticket.status.name.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 20),
                _TicketRow('NAME', ticket.attendeeName),
                _TicketRow('TIER', ticket.priceTierLabel),
                _TicketRow('PAID', ticket.formattedAmount),
                if (ticket.scannedAt != null)
                  _TicketRow('SCANNED AT',
                      DateFormat('d MMM yyyy • HH:mm').format(ticket.scannedAt!.toLocal())),
                const SizedBox(height: 12),
                Divider(color: AppTheme.textMain.withOpacity(0.15)),
                const SizedBox(height: 8),
                Text(
                  'Show this QR at the gate. Each code is single-use only.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceMono(
                      fontSize: 9, color: AppTheme.textMain.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final String label;
  final String value;
  const _TicketRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.spaceMono(fontSize: 10,
                color: AppTheme.textMain.withOpacity(0.5), fontWeight: FontWeight.bold)),
            Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.bold));
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 13, color: AppTheme.primaryMagenta),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: GoogleFonts.spaceMono(fontSize: 10, color: AppTheme.textMain.withOpacity(0.7))),
        ),
      ]);
}

class _TierRadio extends StatelessWidget {
  final PriceTier tier;
  final bool selected;
  final VoidCallback onTap;
  const _TierRadio({required this.tier, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryMagenta.withOpacity(0.06) : Colors.white,
            border: Border.all(
              color: selected ? AppTheme.primaryMagenta : AppTheme.textMain.withOpacity(0.3),
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selected ? AppTheme.primaryMagenta : AppTheme.textMain,
                  size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(tier.label,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Text(tier.formattedPrice,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900, fontSize: 16,
                      color: selected ? AppTheme.primaryMagenta : AppTheme.textMain)),
            ],
          ),
        ),
      );
}

class _BrutalField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final bool required;
  final TextInputType? keyboardType;
  const _BrutalField({
    required this.ctrl, required this.label, required this.hint,
    this.required = true, this.keyboardType,
  });
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextFormField(
            controller: ctrl,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppTheme.textMain, width: 2),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppTheme.primaryMagenta, width: 2),
              ),
              errorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
            ),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
                : null,
          ),
        ],
      );
}
