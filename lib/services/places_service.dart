import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'location_service.dart';
import 'establishments_service.dart';

/// Busca serviços pet reais via Google Places API
/// Documentação: https://developers.google.com/maps/documentation/places/web-service
class PlacesService {
  static final PlacesService _i = PlacesService._();
  factory PlacesService() => _i;
  PlacesService._();

  // ⚠️  Substitua pela sua chave da Google Cloud Console
  // Habilite: Places API + Maps SDK for Android/iOS
  static const _apiKey = 'SUA_GOOGLE_PLACES_API_KEY_AQUI';
  static const _baseUrl =
      'https://maps.googleapis.com/maps/api/place';

  // Mapeamento categoria Fucinho → keyword Google Places
  static const _keywords = {
    Cat.vet:     'veterinário',
    Cat.shop:    'pet shop',
    Cat.banho:   'banho e tosa cachorro',
    Cat.hotel:   'hotel para animais',
    Cat.passeio: 'dog walker passeador',
    Cat.adest:   'adestrador de cães',
  };

  // ── Busca serviços reais por categoria e localização ─────────────
  Future<List<ServiceModel>> fetchNearby({
    required double lat,
    required double lng,
    required String category,
    int radiusMeters = 5000,
  }) async {
    final keyword = _keywords[category] ?? category;
    final url = Uri.parse(
      '$_baseUrl/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=$radiusMeters'
      '&keyword=${Uri.encodeComponent(keyword)}'
      '&language=pt-BR'
      '&key=$_apiKey',
    );

    try {
      final response =
          await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String;

      if (status == 'REQUEST_DENIED') {
        // API key inválida — retorna mock com aviso
        return _mockFallback(lat, lng, category);
      }

      if (status != 'OK' && status != 'ZERO_RESULTS') {
        throw Exception('Places API: $status');
      }

      final results = (json['results'] as List<dynamic>?) ?? [];
      return results.map((r) => _fromPlacesResult(r, category, lat, lng)).toList();
    } catch (_) {
      // Qualquer erro → dados mock
      return _mockFallback(lat, lng, category);
    }
  }

  // ── Busca todas as categorias em paralelo ────────────────────────
  Future<List<ServiceModel>> fetchAll({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
  }) async {
    // Estabelecimentos cadastrados pelo admin: busca TODOS sem filtro de raio.
    // Cada um recebe a distância calculada em relação ao usuário para exibição.
    final rawSupabase = await EstablishmentsService().fetchAll();
    final supabase = rawSupabase
        .map((s) => s.withDist(LocationService.distanceKm(lat, lng, s.lat, s.lng)))
        .toList();
    final supabaseIds = supabase.map((s) => s.id).toSet();

    // Google Places / mock como complemento (apenas para o raio solicitado)
    final futures = Cat.all.map((cat) => fetchNearby(
          lat: lat,
          lng: lng,
          category: cat,
          radiusMeters: radiusMeters,
        ));
    final results = await Future.wait(futures);
    final google = results
        .expand((list) => list)
        .where((s) => !supabaseIds.contains(s.id))
        .map((s) => s.withDist(LocationService.distanceKm(lat, lng, s.lat, s.lng)))
        .toList();

    return [...supabase, ...google]
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  // ── Detalhe de um lugar (foto, telefone, horário) ────────────────
  Future<Map<String, dynamic>?> fetchDetails(String placeId) async {
    final url = Uri.parse(
      '$_baseUrl/details/json'
      '?place_id=$placeId'
      '&fields=name,formatted_phone_number,opening_hours,photos,rating,user_ratings_total'
      '&language=pt-BR'
      '&key=$_apiKey',
    );

    try {
      final resp =
          await http.get(url).timeout(const Duration(seconds: 8));
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (json['status'] == 'OK') return json['result'];
    } catch (_) {}
    return null;
  }

  // ── URL de foto do Google Places ────────────────────────────────
  static String photoUrl(String photoReference, {int maxWidth = 400}) =>
      '$_baseUrl/photo'
      '?maxwidth=$maxWidth'
      '&photo_reference=$photoReference'
      '&key=$_apiKey';

  // ── Converte resultado da API para ServiceModel ──────────────────
  ServiceModel _fromPlacesResult(
      Map<String, dynamic> r, String category, double uLat, double uLng) {
    final loc = r['geometry']?['location'];
    final lat = (loc?['lat'] ?? uLat).toDouble();
    final lng = (loc?['lng'] ?? uLng).toDouble();

    final photos = (r['photos'] as List<dynamic>? ?? [])
        .map((p) => photoUrl(p['photo_reference'] as String))
        .toList();

    return ServiceModel(
      id: r['place_id'] ?? '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}',
      name: r['name'] ?? 'Sem nome',
      category: category,
      address: r['vicinity'] ?? r['formatted_address'] ?? '',
      lat: lat,
      lng: lng,
      rating: (r['rating'] ?? 0.0).toDouble(),
      reviewCount: r['user_ratings_total'] ?? 0,
      isOpen: r['opening_hours']?['open_now'] ?? true,
      photoUrls: photos,
      distanceKm:
          LocationService.distanceKm(uLat, uLng, lat, lng),
    );
  }

  // ── Fallback com dados mock se API não configurada ───────────────
  List<ServiceModel> _mockFallback(
      double lat, double lng, String category) {
    return MockData.services(lat, lng)
        .where((s) => s.category == category)
        .toList();
  }
}
