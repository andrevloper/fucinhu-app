import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_config.dart';

class PetService {
  static final PetService _i = PetService._();
  factory PetService() => _i;
  PetService._();

  SupabaseClient get _db => Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  // ── Listar pets do usuário ────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPets() async {
    if (_uid == null) return [];
    final res = await _db
        .from('pets')
        .select()
        .eq('owner_id', _uid!)
        .order('created_at');
    return List<Map<String, dynamic>>.from(res);
  }

  // ── Criar pet ─────────────────────────────────────────────────────
  Future<({bool success, String? error, Map<String, dynamic>? pet})> createPet({
    required String name,
    required String species,
    required String breed,
    required int ageMonths,
    String? notes,
    File? photoFile,
  }) async {
    if (_uid == null) {
      return (success: false, error: 'Não autenticado.', pet: null);
    }

    try {
      String? photoUrl;

      // Faz upload da foto se fornecida
      if (photoFile != null) {
        photoUrl = await _uploadPhoto(photoFile);
      }

      final data = {
        'owner_id': _uid,
        'name': name.trim(),
        'species': species,
        'breed': breed.trim(),
        'age_months': ageMonths,
        'notes': notes?.trim() ?? '',
        'photo_url': photoUrl,
      };

      final res = await _db.from('pets').insert(data).select().single();

      return (success: true, error: null, pet: res);
    } catch (e) {
      return (success: false, error: 'Erro ao salvar pet: $e', pet: null);
    }
  }

  // ── Atualizar pet ─────────────────────────────────────────────────
  Future<({bool success, String? error})> updatePet({
    required String petId,
    required String name,
    required String species,
    required String breed,
    required int ageMonths,
    String? notes,
    File? photoFile,
    String? existingPhotoUrl,
  }) async {
    if (_uid == null) return (success: false, error: 'Não autenticado.');

    try {
      String? photoUrl = existingPhotoUrl;

      if (photoFile != null) {
        photoUrl = await _uploadPhoto(photoFile);
      }

      await _db
          .from('pets')
          .update({
            'name': name.trim(),
            'species': species,
            'breed': breed.trim(),
            'age_months': ageMonths,
            'notes': notes?.trim() ?? '',
            if (photoUrl != null) 'photo_url': photoUrl,
          })
          .eq('id', petId)
          .eq('owner_id', _uid!);

      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: 'Erro ao atualizar pet: $e');
    }
  }

  // ── Deletar pet ───────────────────────────────────────────────────
  Future<bool> deletePet(String petId) async {
    if (_uid == null) return false;
    try {
      await _db.from('pets').delete().eq('id', petId).eq('owner_id', _uid!);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Upload de foto para o Supabase Storage ────────────────────────
  Future<String> _uploadPhoto(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final fileName = '$_uid/${const Uuid().v4()}.$ext';

    await _db.storage
        .from(SupabaseConfig.petPhotosBucket)
        .upload(fileName, file,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ));

    return _db.storage
        .from(SupabaseConfig.petPhotosBucket)
        .getPublicUrl(fileName);
  }
}
