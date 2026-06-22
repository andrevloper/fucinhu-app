// ─────────────────────────────────────────
// UserModel
// ─────────────────────────────────────────
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final List<String> favoriteIds;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.favoriteIds = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> m, String id) => UserModel(
        id: id,
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        photoUrl: m['photoUrl'],
        favoriteIds: List<String>.from(m['favoriteIds'] ?? []),
      );

  Map<String, dynamic> toMap() => {
        'name': name, 'email': email, 'phone': phone,
        'photoUrl': photoUrl, 'favoriteIds': favoriteIds,
      };

  UserModel copyWith({String? name, String? phone, String? photoUrl,
      List<String>? favoriteIds}) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        favoriteIds: favoriteIds ?? this.favoriteIds,
      );
}

// ─────────────────────────────────────────
// PetModel
// ─────────────────────────────────────────
class PetModel {
  final String id;
  final String ownerId;
  final String name;
  final String species; // Cachorro | Gato | Outro
  final String breed;
  final int ageMonths;
  final String? photoUrl;
  final String notes;

  const PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.breed,
    required this.ageMonths,
    this.photoUrl,
    this.notes = '',
  });

  String get ageLabel {
    if (ageMonths < 12) return '$ageMonths ${ageMonths == 1 ? "mês" : "meses"}';
    final y = ageMonths ~/ 12;
    return '$y ${y == 1 ? "ano" : "anos"}';
  }

  String get speciesEmoji =>
      species == 'Cachorro' ? '🐶' : species == 'Gato' ? '🐱' : '🐾';

  factory PetModel.fromMap(Map<String, dynamic> m, String id) => PetModel(
        id: id, ownerId: m['ownerId'] ?? '', name: m['name'] ?? '',
        species: m['species'] ?? '', breed: m['breed'] ?? '',
        ageMonths: m['ageMonths'] ?? 0, photoUrl: m['photoUrl'],
        notes: m['notes'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId, 'name': name, 'species': species,
        'breed': breed, 'ageMonths': ageMonths,
        'photoUrl': photoUrl, 'notes': notes,
      };
}

// ─────────────────────────────────────────
// ServiceCategory
// ─────────────────────────────────────────
class Cat {
  static const vet      = 'Veterinário';
  static const shop     = 'Pet Shop';
  static const banho    = 'Banho e Tosa';
  static const hotel    = 'Hotel Pet';
  static const passeio  = 'Passeador';
  static const adest    = 'Adestrador';
  static const all = [vet, shop, banho, hotel, passeio, adest];
}

// ─────────────────────────────────────────
// ServiceModel
// ─────────────────────────────────────────
class ServiceModel {
  final String id;
  final String name;
  final String category;
  final String address;
  final double lat;
  final double lng;
  final double rating;
  final int reviewCount;
  final String phone;
  final String whatsapp;
  final String description;
  final List<String> photoUrls;
  final Map<String, String> hours;
  final bool isOpen;
  final bool isFeatured;
  final double distanceKm;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.lat,
    required this.lng,
    this.rating = 0,
    this.reviewCount = 0,
    this.phone = '',
    this.whatsapp = '',
    this.description = '',
    this.photoUrls = const [],
    this.hours = const {},
    this.isOpen = true,
    this.isFeatured = false,
    this.distanceKm = 0,
  });

  ServiceModel withDist(double km) => ServiceModel(
      id: id, name: name, category: category, address: address,
      lat: lat, lng: lng, rating: rating, reviewCount: reviewCount,
      phone: phone, whatsapp: whatsapp, description: description,
      photoUrls: photoUrls, hours: hours, isOpen: isOpen,
      isFeatured: isFeatured, distanceKm: km);

  String get distLabel {
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Status aberto/fechado calculado em tempo real.
  /// Se não houver horários cadastrados, usa o campo [isOpen] da API.
  bool get isCurrentlyOpen {
    if (hours.isEmpty) return isOpen;

    final now = DateTime.now();
    final today = now.weekday; // 1=Seg … 7=Dom
    final nowMin = now.hour * 60 + now.minute;

    const abbr = {
      'Seg': 1, 'Ter': 2, 'Qua': 3, 'Qui': 4,
      'Sex': 5, 'Sáb': 6, 'Dom': 7,
    };

    for (final e in hours.entries) {
      final key = e.key.trim();
      final rawVal = e.value.trim();
      final val = rawVal.toLowerCase();

      bool match = false;
      if (key.contains('–') || key.contains('-')) {
        final parts = key.split(RegExp(r'[–\-]'));
        if (parts.length == 2) {
          final startDay = abbr[parts[0].trim()];
          final endDay   = abbr[parts[1].trim()];
          if (startDay != null && endDay != null) {
            match = today >= startDay && today <= endDay;
          }
        }
      } else {
        match = abbr[key] == today;
      }
      if (!match) continue;

      if (val.contains('24')) return true;
      if (val == 'fechado' || val == 'closed') return false;

      final timeParts = rawVal.split(RegExp(r'[–\-]'));
      if (timeParts.length == 2) {
        final open  = _parseMin(timeParts[0].trim());
        final close = _parseMin(timeParts[1].trim());
        if (open != null && close != null) return nowMin >= open && nowMin < close;
      }
      return true; // dia bate, mas não conseguiu parsear o horário
    }
    return false; // hoje não está nos dias cadastrados
  }

  static int? _parseMin(String t) {
    final m = RegExp(r'(\d+):(\d+)').firstMatch(t);
    if (m == null) return null;
    return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
  }

  /// Ordem canônica dos dias para exibição.
  static const _dayOrder = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  static int _dayWeight(String key) {
    for (int i = 0; i < _dayOrder.length; i++) {
      if (key.startsWith(_dayOrder[i])) return i;
    }
    return 99;
  }

  /// Horários ordenados em ordem de calendário (Seg→Dom).
  List<MapEntry<String, String>> get sortedHours =>
      hours.entries.toList()
        ..sort((a, b) => _dayWeight(a.key).compareTo(_dayWeight(b.key)));

  factory ServiceModel.fromMap(Map<String, dynamic> m, String id) =>
      ServiceModel(
        id: id, name: m['name'] ?? '', category: m['category'] ?? '',
        address: m['address'] ?? '',
        lat: (m['lat'] ?? 0).toDouble(), lng: (m['lng'] ?? 0).toDouble(),
        rating: (m['rating'] ?? 0).toDouble(),
        reviewCount: m['reviewCount'] ?? 0,
        phone: m['phone'] ?? '', whatsapp: m['whatsapp'] ?? '',
        description: m['description'] ?? '',
        photoUrls: List<String>.from(m['photoUrls'] ?? []),
        hours: Map<String, String>.from(m['hours'] ?? {}),
        isOpen: m['isOpen'] ?? true,
      );
}

// ─────────────────────────────────────────
// ReviewModel
// ─────────────────────────────────────────
class ReviewModel {
  final String id;
  final String serviceId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.serviceId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> m) {
    final profiles = m['profiles'] as Map<String, dynamic>?;
    return ReviewModel(
      id: m['id'] as String,
      serviceId: m['service_id'] as String,
      userId: m['user_id'] as String,
      userName: profiles?['name'] as String? ?? 'Usuário',
      userPhotoUrl: profiles?['photo_url'] as String?,
      rating: m['rating'] as int,
      comment: m['comment'] as String? ?? '',
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}

// ─────────────────────────────────────────
// Mock data
// ─────────────────────────────────────────
class MockData {
  static List<ServiceModel> services(double uLat, double uLng) {
    double d(double lat, double lng) =>
        (((lat - uLat).abs() + (lng - uLng).abs()) * 111).clamp(0.1, 50.0);

    final list = [
      ServiceModel(id:'1', name:'Clínica Vet Vida Animal', category:Cat.vet,
          address:'Rua das Flores, 123', lat:uLat+0.005, lng:uLng+0.003,
          rating:4.9, reviewCount:312, phone:'(11) 3333-1111',
          whatsapp:'11933331111', isOpen:true,
          description:'Clínica veterinária completa 24h, cirurgia e vacinação.',
          hours:const {'Seg–Sex':'08:00–20:00','Sáb':'08:00–16:00'}),
      ServiceModel(id:'2', name:'Pet Shop Patinhas', category:Cat.shop,
          address:'Av. Principal, 456', lat:uLat-0.003, lng:uLng+0.007,
          rating:4.7, reviewCount:198, phone:'(11) 4444-2222',
          whatsapp:'11944442222', isOpen:true,
          description:'Rações, acessórios e brinquedos para seu pet.',
          hours:const {'Seg–Sex':'09:00–19:00','Dom':'10:00–15:00'}),
      ServiceModel(id:'3', name:'Banho & Tosa Premium', category:Cat.banho,
          address:'Rua das Acácias, 78', lat:uLat+0.008, lng:uLng-0.004,
          rating:4.8, reviewCount:274, phone:'(11) 5555-3333',
          whatsapp:'11955553333', isOpen:true,
          description:'Banho, tosa artística e hidratação com produtos naturais.',
          hours:const {'Seg–Sáb':'08:00–18:00'}),
      ServiceModel(id:'4', name:'Hotel Pet Paradise', category:Cat.hotel,
          address:'Estrada do Campo, 900', lat:uLat-0.006, lng:uLng-0.008,
          rating:4.6, reviewCount:145, phone:'(11) 6666-4444',
          whatsapp:'11966664444', isOpen:true,
          description:'Hospedagem segura com câmeras 24h.',
          hours:const {'Seg–Dom':'24 horas'}),
      ServiceModel(id:'5', name:'Dog Walker Pro', category:Cat.passeio,
          address:'Rua Verde, 22', lat:uLat+0.002, lng:uLng+0.009,
          rating:4.9, reviewCount:87, phone:'(11) 7777-5555',
          whatsapp:'11977775555', isOpen:true,
          description:'Passeios individuais e em grupo com GPS em tempo real.',
          hours:const {'Seg–Dom':'06:00–20:00'}),
      ServiceModel(id:'6', name:'Adestramento Alpha', category:Cat.adest,
          address:'Av. dos Cães, 310', lat:uLat-0.009, lng:uLng+0.005,
          rating:5.0, reviewCount:56, phone:'(11) 8888-6666',
          whatsapp:'11988886666', isOpen:false,
          description:'Adestramento positivo para cães de todas as raças.',
          hours:const {'Seg–Sex':'07:00–17:00'}),
    ];
    return list.map((s) => s.withDist(d(s.lat, s.lng))).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }
}
