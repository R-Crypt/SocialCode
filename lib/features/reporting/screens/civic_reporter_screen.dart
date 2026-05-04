import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/models/app_user.dart';
import 'package:social_code/models/civic_report.dart';
import 'package:social_code/services/report_service.dart';

class CivicReporterScreen extends StatefulWidget {
  final AppUser user;
  const CivicReporterScreen({super.key, required this.user});

  @override
  State<CivicReporterScreen> createState() => _CivicReporterScreenState();
}

class _CivicReporterScreenState extends State<CivicReporterScreen> {
  final MapController _mapController = MapController();
  List<CivicReport> _reports = [];
  bool _loading = true;
  Position? _userPosition;

  static const _defaultCenter = LatLng(12.9716, 77.5946); // Bengaluru

  @override
  void initState() {
    super.initState();
    _loadReports();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _userPosition = pos);
        _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
      }
    } catch (_) {}
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    try {
      final service = context.read<ReportService>();
      final reports = await service.getReports();
      if (mounted) setState(() { _reports = reports; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12.0,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.socialcode.app',
              ),
              MarkerLayer(
                markers: [
                  if (_userPosition != null)
                    Marker(
                      point: LatLng(
                          _userPosition!.latitude, _userPosition!.longitude),
                      child: const Icon(Icons.my_location,
                          color: AppTheme.accentPurple, size: 28),
                    ),
                  ..._reports.map(
                    (report) => Marker(
                      point: LatLng(report.latitude, report.longitude),
                      child: GestureDetector(
                        onTap: () => _showReportDetail(report),
                        child: Tooltip(
                          message: report.title,
                          child: Icon(
                            _categoryIcon(report.category),
                            color: _statusColor(report.status),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Header overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.borderBlack, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: AppTheme.borderBlack, size: 20),
                    const SizedBox(width: 12),
                    Text('CITY ISSUE MAP',
                        style: GoogleFonts.spaceMono(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppTheme.borderBlack)),
                    const Spacer(),
                    if (_loading)
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryMagenta, strokeWidth: 2))
                    else
                      Text('${_reports.length} ISSUES',
                          style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: AppTheme.primaryMagenta,
                              fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          // FAB + stats banner
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () => _showReportForm(),
                  backgroundColor: AppTheme.primaryMagenta,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  child: const Icon(Icons.add_location_alt, color: Colors.white),
                ),
                const SizedBox(height: 12),
                _StatsBanner(reports: _reports),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(ReportCategory cat) {
    switch (cat) {
      case ReportCategory.pothole: return Icons.radio_button_checked;
      case ReportCategory.waste: return Icons.delete;
      case ReportCategory.streetlight: return Icons.lightbulb;
      case ReportCategory.water: return Icons.water_drop;
      case ReportCategory.tree: return Icons.park;
      case ReportCategory.other: return Icons.warning;
    }
  }

  Color _statusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.reported: return AppTheme.primaryMagenta;
      case ReportStatus.in_progress: return Colors.orange;
      case ReportStatus.resolved: return Colors.green;
      case ReportStatus.rejected: return Colors.grey;
    }
  }

  void _showReportDetail(CivicReport report) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(report.categoryEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report.title.toUpperCase(),
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(report.status).withOpacity(0.1),
                border: Border.all(color: _statusColor(report.status)),
              ),
              child: Text(report.statusLabel,
                  style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(report.status))),
            ),
            const SizedBox(height: 12),
            if (report.description != null) ...[
              Text(report.description!,
                  style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
              const SizedBox(height: 8),
            ],
            Text('REPORTED BY ${report.userName.toUpperCase()}',
                style: GoogleFonts.spaceMono(
                    fontSize: 10, color: AppTheme.borderBlack.withOpacity(0.4))),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.thumb_up, size: 16, color: AppTheme.borderBlack.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text('${report.upvotes} UPVOTES',
                    style: GoogleFonts.spaceMono(fontSize: 11)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    await context.read<ReportService>().upvoteReport(report.id, widget.user.id);
                    Navigator.pop(context);
                    _loadReports();
                  },
                  icon: const Icon(Icons.thumb_up, size: 14),
                  label: const Text('UPVOTE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                    minimumSize: const Size(80, 36),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReportForm() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    ReportCategory selectedCategory = ReportCategory.pothole;
    XFile? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REPORT AN ISSUE',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900, fontSize: 22)),
              const SizedBox(height: 20),

              // Category chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ReportCategory.values.map((cat) {
                    final isSelected = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedCategory = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryMagenta
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryMagenta
                                : AppTheme.borderBlack,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          cat.name.toUpperCase(),
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.borderBlack,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'ISSUE TITLE',
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppTheme.borderBlack, width: 2)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide:
                          BorderSide(color: AppTheme.primaryMagenta, width: 2)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'DESCRIBE THE ISSUE...',
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppTheme.borderBlack, width: 2)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide:
                          BorderSide(color: AppTheme.primaryMagenta, width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final service = context.read<ReportService>();
                    final lat = _userPosition?.latitude ?? 12.9716;
                    final lng = _userPosition?.longitude ?? 77.5946;
                    await service.createReport(
                      userId: widget.user.id,
                      userName: widget.user.displayName,
                      title: titleController.text.trim(),
                      description: descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : null,
                      category: selectedCategory,
                      latitude: lat,
                      longitude: lng,
                      locationName:
                          '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                      imageFilePath: selectedImage?.path,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _loadReports();
                    }
                  },
                  child: const Text('SUBMIT REPORT →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsBanner extends StatelessWidget {
  final List<CivicReport> reports;
  const _StatsBanner({required this.reports});

  @override
  Widget build(BuildContext context) {
    final resolved = reports.where((r) => r.status == ReportStatus.resolved).length;
    final inProgress = reports.where((r) => r.status == ReportStatus.in_progress).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderBlack, width: 1.5),
      ),
      child: Row(
        children: [
          _Stat('${reports.length}', 'REPORTED'),
          const SizedBox(width: 20),
          _Stat('$inProgress', 'IN PROGRESS'),
          const SizedBox(width: 20),
          _Stat('$resolved', 'RESOLVED'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.borderBlack)),
        Text(label,
            style: TextStyle(
                fontSize: 8,
                color: AppTheme.borderBlack.withOpacity(0.4),
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
