import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class FavoritesService {
  static final FavoritesService _i = FavoritesService._();
  factory FavoritesService() => _i;
  FavoritesService._();

  // Sinaliza qualquer mudança nos favoritos para que telas possam reagir
  static final ValueNotifier<int> notifier = ValueNotifier(0);

  SupabaseClient get _db => Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  // ── IDs para checagem rápida (coração nos cards) ──────────────────
  Future<Set<String>> getFavoriteIds() async {
    if (_uid == null) return {};
    try {
      final res = await _db
          .from('favorites')
          .select('service_id')
          .eq('user_id', _uid!);
      return (res as List).map((r) => r['service_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  // ── Lista completa de favoritos (tela de favoritos) ───────────────
  Future<List<ServiceModel>> getFavorites() async {
    if (_uid == null) return [];
    try {
      final res = await _db
          .from('favorites')
          .select()
          .eq('user_id', _uid!)
          .order('created_at', ascending: false);
      return (res as List).map((r) => ServiceModel(
            id: r['service_id'] as String,
            name: r['service_name'] as String? ?? '',
            category: r['service_category'] as String? ?? '',
            address: r['service_address'] as String? ?? '',
            rating: (r['service_rating'] as num?)?.toDouble() ?? 0,
            isOpen: r['service_is_open'] as bool? ?? true,
            lat: (r['service_lat'] as num?)?.toDouble() ?? 0,
            lng: (r['service_lng'] as num?)?.toDouble() ?? 0,
            photoUrls: List<String>.from(
                r['service_photo_urls'] as List? ?? []),
          )).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Adicionar favorito (salva dados do serviço junto) ─────────────
  Future<bool> addFavorite(ServiceModel service) async {
    if (_uid == null) return false;
    try {
      await _db.from('favorites').upsert({
        'user_id': _uid,
        'service_id': service.id,
        'service_name': service.name,
        'service_category': service.category,
        'service_address': service.address,
        'service_rating': service.rating,
        'service_is_open': service.isOpen,
        'service_lat': service.lat,
        'service_lng': service.lng,
        'service_photo_urls': service.photoUrls,
      });
      notifier.value++;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Remover favorito ──────────────────────────────────────────────
  Future<bool> removeFavorite(String serviceId) async {
    if (_uid == null) return false;
    try {
      await _db
          .from('favorites')
          .delete()
          .eq('user_id', _uid!)
          .eq('service_id', serviceId);
      notifier.value++;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Toggle ────────────────────────────────────────────────────────
  Future<bool> toggle(ServiceModel service, Set<String> currentFavs) async {
    if (currentFavs.contains(service.id)) {
      return removeFavorite(service.id);
    } else {
      return addFavorite(service);
    }
  }
}
