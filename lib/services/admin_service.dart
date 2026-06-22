import 'package:supabase_flutter/supabase_flutter.dart';
import 'establishments_service.dart';

class AdminProfile {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final bool isAdmin;
  final DateTime createdAt;
  final String email;
  final int petCount;
  final int favoriteCount;

  const AdminProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
    required this.isAdmin,
    required this.createdAt,
    required this.email,
    this.petCount = 0,
    this.favoriteCount = 0,
  });
}

class AdminPet {
  final String id;
  final String ownerId;
  final String ownerName;
  final String name;
  final String species;
  final String breed;
  final int ageMonths;
  final String? photoUrl;
  final DateTime createdAt;

  const AdminPet({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.name,
    required this.species,
    required this.breed,
    required this.ageMonths,
    this.photoUrl,
    required this.createdAt,
  });

  String get ageLabel {
    if (ageMonths < 12) return '$ageMonths ${ageMonths == 1 ? "mês" : "meses"}';
    final y = ageMonths ~/ 12;
    return '$y ${y == 1 ? "ano" : "anos"}';
  }

  String get speciesEmoji =>
      species == 'Cachorro' ? '🐶' : species == 'Gato' ? '🐱' : '🐾';
}

class AdminFavorite {
  final String id;
  final String userId;
  final String userName;
  final String serviceId;
  final String serviceName;
  final String serviceCategory;
  final String serviceAddress;
  final double serviceRating;
  final bool serviceIsOpen;
  final DateTime createdAt;

  const AdminFavorite({
    required this.id,
    required this.userId,
    required this.userName,
    required this.serviceId,
    required this.serviceName,
    required this.serviceCategory,
    required this.serviceAddress,
    required this.serviceRating,
    required this.serviceIsOpen,
    required this.createdAt,
  });
}

class AdminStats {
  final int totalUsers;
  final int totalPets;
  final int totalFavorites;
  final int totalEstablishments;
  final Map<String, int> petsBySpecies;
  final List<PopularService> topServices;

  const AdminStats({
    required this.totalUsers,
    required this.totalPets,
    required this.totalFavorites,
    required this.totalEstablishments,
    required this.petsBySpecies,
    required this.topServices,
  });
}

class PopularService {
  final String serviceId;
  final String serviceName;
  final String serviceCategory;
  final int count;
  const PopularService({
    required this.serviceId,
    required this.serviceName,
    required this.serviceCategory,
    required this.count,
  });
}

class AdminService {
  static final AdminService _i = AdminService._();
  factory AdminService() => _i;
  AdminService._();

  SupabaseClient get _db => Supabase.instance.client;

  Future<bool> isAdmin() async {
    try {
      final result = await _db.rpc('is_current_user_admin');
      return result as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<AdminProfile>> getUsers() async {
    try {
      final profiles = await _db
          .from('profiles')
          .select('id, name, phone, photo_url, is_admin, created_at')
          .order('created_at', ascending: false);

      final pets = await _db.from('pets').select('owner_id');
      final favs = await _db.from('favorites').select('user_id');

      final petCounts = <String, int>{};
      for (final p in pets as List) {
        final oid = p['owner_id'] as String;
        petCounts[oid] = (petCounts[oid] ?? 0) + 1;
      }

      final favCounts = <String, int>{};
      for (final f in favs as List) {
        final uid = f['user_id'] as String;
        favCounts[uid] = (favCounts[uid] ?? 0) + 1;
      }

      // email vem da auth.users, mas com anon key não temos acesso direto.
      // Usamos o id como referência e deixamos email vazio por segurança.
      return (profiles as List).map((r) {
        final id = r['id'] as String;
        return AdminProfile(
          id: id,
          name: r['name'] as String? ?? '',
          phone: r['phone'] as String? ?? '',
          photoUrl: r['photo_url'] as String?,
          isAdmin: r['is_admin'] as bool? ?? false,
          createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
              DateTime.now(),
          email: '',
          petCount: petCounts[id] ?? 0,
          favoriteCount: favCounts[id] ?? 0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<AdminPet>> getPets() async {
    try {
      final res = await _db
          .from('pets')
          .select('id, owner_id, name, species, breed, age_months, photo_url, created_at, profiles(name)')
          .order('created_at', ascending: false);

      return (res as List).map((r) {
        final profile = r['profiles'] as Map<String, dynamic>?;
        return AdminPet(
          id: r['id'] as String,
          ownerId: r['owner_id'] as String,
          ownerName: profile?['name'] as String? ?? 'Desconhecido',
          name: r['name'] as String? ?? '',
          species: r['species'] as String? ?? '',
          breed: r['breed'] as String? ?? '',
          ageMonths: r['age_months'] as int? ?? 0,
          photoUrl: r['photo_url'] as String?,
          createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<AdminFavorite>> getFavorites() async {
    try {
      final res = await _db
          .from('favorites')
          .select('id, user_id, service_id, service_name, service_category, service_address, service_rating, service_is_open, created_at, profiles(name)')
          .order('created_at', ascending: false);

      return (res as List).map((r) {
        final profile = r['profiles'] as Map<String, dynamic>?;
        return AdminFavorite(
          id: r['id'] as String,
          userId: r['user_id'] as String,
          userName: profile?['name'] as String? ?? 'Desconhecido',
          serviceId: r['service_id'] as String? ?? '',
          serviceName: r['service_name'] as String? ?? '',
          serviceCategory: r['service_category'] as String? ?? '',
          serviceAddress: r['service_address'] as String? ?? '',
          serviceRating: (r['service_rating'] as num?)?.toDouble() ?? 0,
          serviceIsOpen: r['service_is_open'] as bool? ?? true,
          createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<AdminStats> getStats() async {
    final results = await Future.wait([
      getUsers(),
      getPets(),
      getFavorites(),
      EstablishmentsService().fetchAll(),
    ]);

    final users = results[0] as List;
    final pets  = results[1] as List;
    final favs  = results[2] as List;
    final estab = results[3] as List;

    final petsBySpecies = <String, int>{};
    for (final p in pets) {
      petsBySpecies[p.species] = (petsBySpecies[p.species] ?? 0) + 1;
    }

    final svcCount = <String, PopularService>{};
    for (final f in favs) {
      if (f.serviceId.isEmpty) continue;
      final existing = svcCount[f.serviceId];
      svcCount[f.serviceId] = PopularService(
        serviceId: f.serviceId,
        serviceName: f.serviceName,
        serviceCategory: f.serviceCategory,
        count: (existing == null ? 0 : existing.count) + 1,
      );
    }

    final topServices = svcCount.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return AdminStats(
      totalUsers: users.length,
      totalPets: pets.length,
      totalFavorites: favs.length,
      totalEstablishments: estab.length,
      petsBySpecies: petsBySpecies,
      topServices: topServices.take(10).toList(),
    );
  }
}
