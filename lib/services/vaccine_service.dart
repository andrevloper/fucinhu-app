import 'package:supabase_flutter/supabase_flutter.dart';

class VaccineService {
  static final VaccineService _i = VaccineService._();
  factory VaccineService() => _i;
  VaccineService._();

  SupabaseClient get _db => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getVaccines(String petId) async {
    try {
      final res = await _db
          .from('pet_vaccines')
          .select()
          .eq('pet_id', petId)
          .order('applied_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<bool> addVaccine({
    required String petId,
    required String name,
    required DateTime appliedAt,
    DateTime? nextAt,
    String? vet,
    String? notes,
  }) async {
    try {
      await _db.from('pet_vaccines').insert({
        'pet_id': petId,
        'name': name.trim(),
        'applied_at': appliedAt.toIso8601String().split('T').first,
        if (nextAt != null)
          'next_at': nextAt.toIso8601String().split('T').first,
        if (vet != null && vet.isNotEmpty) 'vet': vet.trim(),
        if (notes != null && notes.isNotEmpty) 'notes': notes.trim(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteVaccine(String vaccineId) async {
    try {
      await _db.from('pet_vaccines').delete().eq('id', vaccineId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
