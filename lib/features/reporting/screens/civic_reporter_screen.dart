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
  List<CivicReport> _allReports = [];
  ReportCategory? _filterCategory;
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
      if (mounted) setState(() { _allReports = reports; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CivicReport> get _filteredReports {
    if (_filterCategory == null) return _allReports;
    return _allReports.where((r) => r.category == _filterCategory).toList();
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
                      child: Icon(Icons.my_location,
                          color: AppTheme.accentPurple, size: 28),
                    ),
                  ..._filteredReports.map(
                    (report) => Marker(
                      width: 45,
                      height: 45,
                      point: LatLng(report.latitude, report.longitude),
                      child: GestureDetector(
                        onTap: () => _showReportDetail(report),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _statusColor(report.status),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(
                              report.categoryEmoji,
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Header + Filters
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Container(
                    height: 52,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.map, size: 20),
                        SizedBox(width: 12),
                        Text('CITY ISSUE MAP',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w900,
                                fontSize: 16)),
                        const Spacer(),
                        if (_loading)
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          Text('${_filteredReports.length} ISSUES',
                              style: GoogleFonts.spaceMono(
                                  fontSize: 10,
                                  color: AppTheme.primaryMagenta,
                                  fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                _buildCategoryFilters(),
              ],
            ),
          ),

          // FAB
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _showReportForm(),
              backgroundColor: AppTheme.primaryMagenta,
              shape: const CircleBorder(),
              child: Icon(Icons.add_location_alt, color: Colors.white),
            ),
          ),
          
          Positioned(
            bottom: 24,
            left: 16,
            child: _StatsBanner(reports: _filteredReports),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterChip(null, 'ALL', '🌍'),
          ...ReportCategory.values.map((cat) => _filterChip(cat, cat.name.toUpperCase(), _categoryEmoji(cat))),
        ],
      ),
    );
  }

  Widget _filterChip(ReportCategory? cat, String label, String emoji) {
    final active = _filterCategory == cat;
    return GestureDetector(
      onTap: () => setState(() => _filterCategory = cat),
      child: Container(
        margin: EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryMagenta : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppTheme.primaryMagenta : Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: 12)),
            SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(ReportCategory cat) {
    switch (cat) {
      case ReportCategory.pothole: return '🕳️';
      case ReportCategory.waste: return '🗑️';
      case ReportCategory.streetlight: return '💡';
      case ReportCategory.water: return '💧';
      case ReportCategory.tree: return '🌳';
      case ReportCategory.noise: return '🔊';
      case ReportCategory.safety: return '🛡️';
      case ReportCategory.misc: return '⚠️';
    }
  }

  IconData _categoryIcon(ReportCategory cat) {
    switch (cat) {
      case ReportCategory.pothole: return Icons.radio_button_checked;
      case ReportCategory.waste: return Icons.delete_outline_rounded;
      case ReportCategory.streetlight: return Icons.lightbulb_outline_rounded;
      case ReportCategory.water: return Icons.water_drop_outlined;
      case ReportCategory.tree: return Icons.park_outlined;
      case ReportCategory.noise: return Icons.volume_up_outlined;
      case ReportCategory.safety: return Icons.shield_outlined;
      case ReportCategory.misc: return Icons.warning_amber_rounded;
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(report.categoryEmoji, style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report.title.toUpperCase(),
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(report.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(report.statusLabel,
                  style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(report.status))),
            ),
            SizedBox(height: 12),
            if (report.description != null) ...[
              Text(report.description!,
                  style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
              SizedBox(height: 8),
            ],
            Text('REPORTED BY ${report.userName.toUpperCase()}',
                style: GoogleFonts.spaceMono(
                    fontSize: 10, color: AppTheme.textDim.withOpacity(0.6))),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.thumb_up, size: 16, color: AppTheme.textDim.withOpacity(0.6)),
                SizedBox(width: 4),
                Text('${report.upvotes} UPVOTES',
                    style: GoogleFonts.spaceMono(fontSize: 11)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    await context.read<ReportService>().upvoteReport(report.id, widget.user.id);
                    Navigator.pop(context);
                    _loadReports();
                  },
                  icon: Icon(Icons.thumb_up, size: 14),
                  label: Text('UPVOTE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMagenta,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              SizedBox(height: 20),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ReportCategory.values.map((cat) {
                    final isSelected = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedCategory = cat),
                      child: Container(
                        margin: EdgeInsets.only(right: 8),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryMagenta
                              : Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryMagenta : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Text(
                          cat.name.toUpperCase(),
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'ISSUE TITLE',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'DESCRIBE THE ISSUE...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 20),
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
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _loadReports();
                    }
                  },
                  child: Text('SUBMIT REPORT →'),
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Stat('${reports.length}', 'REPORTED'),
          SizedBox(width: 16),
          _Stat('$inProgress', 'ONGOING'),
          SizedBox(width: 16),
          _Stat('$resolved', 'FIXED'),
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
                fontSize: 16,
                fontWeight: FontWeight.w900)),
        Text(label,
            style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
      ],
    );
  }
}
