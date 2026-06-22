import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingResult {
  final String displayName;
  final double lat;
  final double lng;

  const GeocodingResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });
}

class GeocodingService {
  static final GeocodingService _i = GeocodingService._();
  factory GeocodingService() => _i;
  GeocodingService._();

  Future<List<GeocodingResult>> search(String query) async {
    if (query.trim().length < 3) return [];

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&addressdetails=1'
      '&limit=5'
      '&countrycodes=br'
      '&accept-language=pt-BR',
    );

    try {
      final resp = await http.get(url, headers: {
        'User-Agent': 'FucinhoCoApp/1.0 (andrejsluiz@gmail.com)',
      }).timeout(const Duration(seconds: 6));

      if (resp.statusCode != 200) return [];

      final list = jsonDecode(resp.body) as List<dynamic>;
      return list.map((item) {
        return GeocodingResult(
          displayName: item['display_name'] as String,
          lat: double.parse(item['lat'] as String),
          lng: double.parse(item['lon'] as String),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
