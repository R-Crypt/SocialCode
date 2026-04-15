import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_theme.dart';

class CivicReporterScreen extends StatefulWidget {
  const CivicReporterScreen({super.key});

  @override
  State<CivicReporterScreen> createState() => _CivicReporterScreenState();
}

class _CivicReporterScreenState extends State<CivicReporterScreen> {
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(12.9716, 77.5946), // Bangalore
    zoom: 12.0,
  );

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('pothole_1'),
      position: LatLng(12.9784, 77.6408),
      infoWindow: InfoWindow(title: 'Pothole Reported', snippet: 'Verification pending'),
    ),
    const Marker(
      markerId: MarkerId('waste_1'),
      position: LatLng(12.9279, 77.6271),
      infoWindow: InfoWindow(title: 'Illegal Waste Dump', snippet: 'Status: Cleanup in progress'),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // The Map
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            mapType: MapType.dark, // Requires dark styling via cloud styling or custom styles
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              // Apply Dark Theme Style (Standard JSON for Google Maps Dark)
            },
          ),

          // Search / Filter Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.white38),
                        SizedBox(width: 12),
                        Text('SEARCH REVENUE REGIONS...', style: TextStyle(color: Colors.white38)),
                        Spacer(),
                        Icon(Icons.tune, color: AppTheme.neonGreen),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Quick Action
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: AppTheme.neonGreen,
                  child: const Icon(Icons.add_location_alt, color: Colors.black),
                ),
                const SizedBox(height: 16),
                _buildImpactBanner(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CITY HEAT MAP: BANGALORE',
            style: GoogleFonts.outfit(
              color: Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildImpactStat('2.9k', 'POTHOLES FIXED'),
              const SizedBox(width: 24),
              _buildImpactStat('1.6k', 'CLEANUPS DONE'),
              const Spacer(),
              const Icon(Icons.show_chart, color: AppTheme.neonGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.black, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
