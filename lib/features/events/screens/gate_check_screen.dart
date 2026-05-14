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
  final MobileScannerController _scannerController = MobileScannerController();
  bool _scanning = false;
  bool _scannerActive = false;
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
    _scannerController.dispose();
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

          // ── Middle: Scanner / Result ────────────────────────────────────────
          Expanded(
            child: _lastResult != null
                ? FadeTransition(
                    opacity: _flashAnim,
                    child: _ResultView(
                      result: _lastResult!,
                      onReset: () => setState(() {
                        _lastResult = null;
                        _scannerActive = true;
                      }),
                    ),
                  )
                : Stack(
                    children: [
                      if (_scannerActive)
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty &&
                                barcodes.first.rawValue != null &&
                                !_scanning) {
                              _verify(barcodes.first.rawValue!);
                            }
                          },
                        )
                      else
                        Container(
                          color: Colors.black12,
                          width: double.infinity,
                          height: double.infinity,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 64, color: Colors.white24),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => setState(() => _scannerActive = true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryMagenta,
                                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  ),
                                  child: Text('ACTIVATE CAMERA',
                                      style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Scanner Overlay
                      if (_scannerActive && _lastResult == null)
                        Center(
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primaryMagenta, width: 4),
                            ),
                            child: Stack(
                              children: [
                                _ScannerCorner(top: 0, left: 0),
                                _ScannerCorner(top: 0, right: 0, rotation: 1.5708),
                                _ScannerCorner(bottom: 0, left: 0, rotation: -1.5708),
                                _ScannerCorner(bottom: 0, right: 0, rotation: 3.14159),
                              ],
                            ),
                          ),
                        ),

                      // Manual Entry Fallback (Bottom)
                      if (_lastResult == null)
                        Positioned(
                          bottom: 24,
                          left: 24,
                          right: 24,
                          child: Column(
                            children: [
                              TextButton.icon(
                                onPressed: () => _showManualEntry(context),
                                icon: Icon(Icons.keyboard, color: Colors.white70),
                                label: Text('MANUAL ENTRY', style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 10)),
                                style: TextButton.styleFrom(backgroundColor: Colors.black45),
                              ),
                            ],
                          ),
                        ),
                    ],
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

  void _showManualEntry(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: AppTheme.primaryMagenta, width: 4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MANUAL TICKET ENTRY', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18)),
            SizedBox(height: 16),
            TextField(
              controller: _tokenCtrl,
              autofocus: true,
              style: GoogleFonts.spaceMono(),
              decoration: InputDecoration(
                hintText: 'Enter QR Token...',
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                filled: true,
              ),
              onSubmitted: (val) {
                Navigator.pop(ctx);
                _verify(val);
              },
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _verify(_tokenCtrl.text);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMagenta),
                child: Text('VERIFY TICKET'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  final double? top, bottom, left, right;
  final double rotation;
  const _ScannerCorner({this.top, this.bottom, this.left, this.right, this.rotation = 0});
  @override
  Widget build(BuildContext context) => Positioned(
    top: top, bottom: bottom, left: left, right: right,
    child: Transform.rotate(
      angle: rotation,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.primaryMagenta, width: 6),
            left: BorderSide(color: AppTheme.primaryMagenta, width: 6),
          ),
        ),
      ),
    ),
  );
}

// ─── Result ───────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final _ScanResult result;
  final VoidCallback onReset;
  const _ResultView({required this.result, required this.onReset});

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
            onPressed: onReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
