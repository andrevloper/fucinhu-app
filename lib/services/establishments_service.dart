import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'location_service.dart';

class EstablishmentsService {
  static final EstablishmentsService _i = EstablishmentsService._();
  factory EstablishmentsService() => _i;
  EstablishmentsService._();

  SupabaseClient get _db => Supabase.instance.client;

  Future<List<ServiceModel>> fetchAll({
    double? lat,
    double? lng,
    double radiusKm = 50,
  }) async {
    try {
      final res = await _db.from('services').select().order('created_at', ascending: false);
      final services = (res as List).cast<Map<String, dynamic>>().map(_fromRow).toList();

      if (lat != null && lng != null) {
        return services
            .map((s) => s.withDist(LocationService.distanceKm(lat, lng, s.lat, s.lng)))
            .where((s) => s.distanceKm <= radiusKm)
            .toList()
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      }
      return services;
    } catch (_) {
      return [];
    }
  }

  Future<ServiceModel?> create(Map<String, dynamic> data) async {
    try {
      final res = await _db.from('services').insert(data).select().single();
      return _fromRow(res);
    } catch (_) {
      return null;
    }
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    try {
      await _db.from('services').update(data).eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _db.from('services').delete().eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  static ServiceModel _fromRow(Map<String, dynamic> r) => ServiceModel(
        id: r['id'] as String,
        name: r['name'] as String? ?? '',
        category: r['category'] as String? ?? '',
        address: r['address'] as String? ?? '',
        lat: (r['lat'] as num?)?.toDouble() ?? 0,
        lng: (r['lng'] as num?)?.toDouble() ?? 0,
        rating: (r['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: r['review_count'] as int? ?? 0,
        phone: r['phone'] as String? ?? '',
        whatsapp: r['whatsapp'] as String? ?? '',
        description: r['description'] as String? ?? '',
        photoUrls: List<String>.from(r['photo_urls'] as List? ?? []),
        hours: Map<String, String>.from(r['hours'] as Map? ?? {}),
        isOpen: r['is_open'] as bool? ?? true,
        isFeatured: r['is_featured'] as bool? ?? false,
      );
}
