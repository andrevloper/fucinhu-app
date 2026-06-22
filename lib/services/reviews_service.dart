import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class ReviewsService {
  static final ReviewsService _i = ReviewsService._();
  factory ReviewsService() => _i;
  ReviewsService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// Lista todas as avaliações de um estabelecimento (mais recentes primeiro).
  Future<List<ReviewModel>> getReviews(String serviceId) async {
    try {
      final res = await _db
          .from('reviews')
          .select('id, service_id, user_id, rating, comment, created_at')
          .eq('service_id', serviceId)
          .order('created_at', ascending: false);
      final rows = List<Map<String, dynamic>>.from(res as List);
      if (rows.isEmpty) return [];

      final userIds = rows.map((r) => r['user_id'] as String).toSet().toList();
      final profilesRes = await _db
          .from('profiles')
          .select('id, name, photo_url')
          .inFilter('id', userIds);
      final profiles = {
        for (final p in List<Map<String, dynamic>>.from(profilesRes as List))
          p['id'] as String: p,
      };

      return rows
          .map((r) => ReviewModel.fromMap({...r, 'profiles': profiles[r['user_id']]}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Retorna a avaliação do usuário logado para este serviço, ou null se não avaliou.
  Future<ReviewModel?> getMyReview(String serviceId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final res = await _db
          .from('reviews')
          .select('id, service_id, user_id, rating, comment, created_at')
          .eq('service_id', serviceId)
          .eq('user_id', uid)
          .maybeSingle();
      if (res == null) return null;

      final profileRes = await _db
          .from('profiles')
          .select('id, name, photo_url')
          .eq('id', uid)
          .maybeSingle();
      return ReviewModel.fromMap({...res, 'profiles': profileRes});
    } catch (_) {
      return null;
    }
  }

  /// Cria ou atualiza a avaliação do usuário logado (upsert por service_id + user_id).
  /// Retorna null em caso de sucesso, ou uma mensagem de erro.
  Future<String?> submitReview({
    required String serviceId,
    required int rating,
    required String comment,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return 'Faça login para avaliar.';
    try {
      await _db.from('reviews').upsert(
        {
          'service_id': serviceId,
          'user_id': uid,
          'rating': rating,
          'comment': comment,
        },
        onConflict: 'service_id,user_id',
      );
      return null;
    } on PostgrestException catch (e) {
      return 'Erro ao salvar: ${e.message}';
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  /// Remove a avaliação do usuário logado para este serviço.
  Future<bool> deleteMyReview(String serviceId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      await _db
          .from('reviews')
          .delete()
          .eq('service_id', serviceId)
          .eq('user_id', uid);
      return true;
    } catch (_) {
      return false;
    }
  }
}
