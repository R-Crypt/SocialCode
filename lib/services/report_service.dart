import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_code/models/civic_report.dart';

class ReportService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<String?> uploadReportImage(String filePath, String userId) async {
    try {
      final file = File(filePath);
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'civic-reports/$fileName';
      await _client.storage.from('civic-reports').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      return _client.storage.from('civic-reports').getPublicUrl(storagePath);
    } catch (e) {
      return null;
    }
  }

  Future<CivicReport> createReport({
    required String userId,
    required String userName,
    required String title,
    String? description,
    required ReportCategory category,
    required double latitude,
    required double longitude,
    String? locationName,
    String? imageFilePath,
  }) async {
    String? imageUrl;
    if (imageFilePath != null) {
      imageUrl = await uploadReportImage(imageFilePath, userId);
    }

    final data = {
      'user_id': userId,
      'user_name': userName,
      'title': title,
      'description': description,
      'category': category.name,
      'status': 'reported',
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'image_url': imageUrl,
    };

    final response = await _client
        .from('civic_reports')
        .insert(data)
        .select()
        .single();
    return CivicReport.fromMap(response, response['id']);
  }

  Future<List<CivicReport>> getReports({
    double? nearLat,
    double? nearLng,
    ReportCategory? category,
    ReportStatus? status,
  }) async {
    var query = _client.from('civic_reports').select();
    if (category != null) {
      query = query.eq('category', category.name) as dynamic;
    }
    if (status != null) {
      query = query.eq('status', status.name) as dynamic;
    }
    final response = await _client
        .from('civic_reports')
        .select()
        .order('created_at', ascending: false)
        .limit(200);
    return (response as List)
        .map((d) => CivicReport.fromMap(d as Map<String, dynamic>, d['id']))
        .toList();
  }

  Future<void> upvoteReport(String reportId, String userId) async {
    try {
      await _client.from('report_upvotes').insert({
        'report_id': reportId,
        'user_id': userId,
      });
      await _client.rpc('increment', params: {
        'table_name': 'civic_reports',
        'row_id': reportId,
        'column_name': 'upvotes',
      });
    } catch (_) {}
  }

  Stream<List<CivicReport>> watchReports() {
    return _client
        .from('civic_reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data
            .map((d) => CivicReport.fromMap(d, d['id']))
            .toList());
  }
}
