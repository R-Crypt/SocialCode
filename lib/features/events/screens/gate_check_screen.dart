import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/models/app_user.dart';
import 'package:social_code/services/ticket_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Gate Check Screen — admin/staff scans QR codes at the event entrance.
///
/// Platform behaviour:
///   • On mobile/web: [mobile_scanner] opens the camera for QR scanning.
///   • Fallback to a token text-field (paste/type QR token).
///
/// The verify_and_use_ticket() PostgreSQL function provides:
///   • Atomic status update (SELECT … FOR UPDATE)
///   • Replay-attack prevention (double-scan detection)
///   • Full audit trail (scanned_at, scanned_by columns)

class GateCheckScreen extends StatefulWidget {
  final AppUser user;
  const GateCheckScreen({super.key, required this.user});

  @override
  State<GateCheckScreen> createState() => _GateCheckScreenState();
}

class _GateCheckScreenState extends State<GateCheckScreen>
    with SingleTickerProviderStateMixin {
  final _svc = TicketService();
  final _tokenCtrl = TextEditingController();

  bool _scanning = false;
  _ScanResult? _lastResult;

  // Animation controller for result flash
  late final AnimationController _flashCtrl;
  late final Animation<double> _flashAnim;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flashAnim = CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  // ─── Verify token (called from text field submit or camera scan) ──────────
  Future<void> _verify(String rawToken) async {
    final token = rawToken.trim();
    if (token.isEmpty) return;

    setState(() { _scanning = true; });

    try {
      final res = await _svc.verifyAndUseTicket(token);
      final success = res['success'] as bool? ?? false;

      final result = _ScanResult(
        success: success,
        message: res['message'] as String? ?? (success ? 'Access Granted' : 'Denied'),
        eventTitle: res['event_title'] as String?,
        attendeeName: res['attendee_name'] as String?,
        tierLabel: res['price_tier_label'] as String?,
        scannedToken: token,
      );

      if (mounted) {
        setState(() { _lastResult = result; _scanning = false; _tokenCtrl.clear(); });
        _flashCtrl.forward(from: 0);
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _lastResult = _ScanResult(
            success: false,
            message: 'Error: $e',
            scannedToken: token,
          );
        });
        _flashCtrl.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'GATE CHECK',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: AppTheme.primaryMagenta),
        ),
      ),
      body: Column(
        children: [
          // ── Top: Title ──────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Theme.of(context).colorScheme.onSurface,
            width: double.infinity,
            child: Text(
              'SCAN TICKET QR',
              style: GoogleFonts.spaceMono(
                  fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          // ── Middle: Result display ────────────────────────────────────────
          Expanded(
            child: _lastResult == null
                ? MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && barcodes.first.rawValue != null && !_scanning) {
                        _verify(barcodes.first.rawValue!);
                      }
                    },
                  )
                : FadeTransition(
                    opacity: _flashAnim,
                    child: _ResultView(result: _lastResult!),
                  ),
          ),

          // ── Bottom: Recent scans counter ─────────────────────────────────
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.white10,
            child: Text(
              'LOGGED IN AS: ${widget.user.displayName.toUpperCase()}  •  ROLE: ${widget.user.role.name.toUpperCase()}',
              style: GoogleFonts.spaceMono(fontSize: 9, color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scanner view removed, using MobileScanner inline ───────────────

// ─── Result ───────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final _ScanResult result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final isGranted = result.success;
    final bgColor = isGranted ? const Color(0xFF0D3B1E) : const Color(0xFF3B0D0D);
    final accentColor = isGranted ? const Color(0xFF22C55E) : Colors.red;
    final icon = isGranted ? Icons.check_circle : Icons.cancel;
    final headline = isGranted ? 'ACCESS GRANTED' : 'ACCESS DENIED';

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 96, color: accentColor),
          SizedBox(height: 20),
          Text(
            headline,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900, fontSize: 32, color: accentColor),
          ),
          SizedBox(height: 8),
          Text(
            result.message,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(fontSize: 12, color: Colors.white70),
          ),
          if (result.attendeeName != null) ...[
            SizedBox(height: 24),
            _ResultRow('ATTENDEE', result.attendeeName!),
          ],
          if (result.eventTitle != null) _ResultRow('EVENT', result.eventTitle!),
          if (result.tierLabel != null) _ResultRow('TIER', result.tierLabel!),
          SizedBox(height: 24),
          Text(
            DateFormat('HH:mm:ss · d MMM yyyy').format(DateTime.now()),
            style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.white38),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
               // Reset to allow scanning again
               final state = context.findAncestorStateOfType<_GateCheckScreenState>();
               state?.setState(() => state._lastResult = null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: Text('SCAN NEXT TICKET'),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$label: ',
                style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.white38)),
            Text(value,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
          ],
        ),
      );
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _ScanResult {
  final bool success;
  final String message;
  final String? eventTitle;
  final String? attendeeName;
  final String? tierLabel;
  final String scannedToken;

  const _ScanResult({
    required this.success,
    required this.message,
    this.eventTitle,
    this.attendeeName,
    this.tierLabel,
    required this.scannedToken,
  });
}
