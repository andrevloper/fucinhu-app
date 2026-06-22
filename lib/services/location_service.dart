import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

/// Resultado da tentativa de obter localização
class LocationResult {
  final double lat;
  final double lng;
  final bool isReal;      // true = GPS real, false = fallback
  final String? error;

  const LocationResult({
    required this.lat,
    required this.lng,
    this.isReal = true,
    this.error,
  });

  // São Paulo como fallback padrão
  static const fallback = LocationResult(
    lat: -23.5505,
    lng: -46.6333,
    isReal: false,
    error: 'Usando localização padrão (São Paulo)',
  );

  @override
  String toString() =>
      'LocationResult(lat: $lat, lng: $lng, isReal: $isReal)';
}

class LocationService {
  // Singleton
  static final LocationService _instance = LocationService._();
  factory LocationService() => _instance;
  LocationService._();

  LocationResult? _cached;
  DateTime? _cachedAt;
  static const _cacheTimeout = Duration(minutes: 2);

  // ── Pede permissão e obtém posição ─────────────────────────────────
  Future<LocationResult> getCurrentLocation() async {
    // Retorna cache se ainda válido
    if (_cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTimeout) {
      return _cached!;
    }

    try {
      // 1. Verifica se o serviço de localização está ativo
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.fallback.copyWith(
            error: 'Serviço de localização desativado no dispositivo.');
      }

      // 2. Verifica/pede permissão
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.fallback
              .copyWith(error: 'Permissão de localização negada.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationResult.fallback.copyWith(
            error: 'Permissão negada permanentemente. '
                'Habilite nas configurações do app.');
      }

      // 3. Obtém posição com timeout de 10 s
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final result = LocationResult(lat: pos.latitude, lng: pos.longitude);
      _cached = result;
      _cachedAt = DateTime.now();
      return result;
    } on TimeoutException {
      // Tenta última posição conhecida antes de usar fallback
      return await _lastKnownOrFallback(
          error: 'Tempo esgotado ao obter localização.');
    } catch (e) {
      return await _lastKnownOrFallback(error: e.toString());
    }
  }

  // ── Última posição conhecida ou fallback ──────────────────────────
  Future<LocationResult> _lastKnownOrFallback({String? error}) async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return LocationResult(
          lat: last.latitude,
          lng: last.longitude,
          isReal: true,
          error: error,
        );
      }
    } catch (_) {}
    return LocationResult.fallback.copyWith(error: error);
  }

  // ── Stream de atualizações de posição ────────────────────────────
  Stream<LocationResult> get positionStream {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // atualiza a cada 50 m
      ),
    ).map((pos) => LocationResult(lat: pos.latitude, lng: pos.longitude));
  }

  // ── Calcula distância em km entre dois pontos (Haversine) ─────────
  static double distanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0; // raio da Terra em km
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _rad(double deg) => deg * math.pi / 180;

  void clearCache() {
    _cached = null;
    _cachedAt = null;
  }
}

extension LocationResultX on LocationResult {
  LocationResult copyWith({
    double? lat,
    double? lng,
    bool? isReal,
    String? error,
  }) =>
      LocationResult(
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        isReal: isReal ?? this.isReal,
        error: error ?? this.error,
      );
}

// Compatibilidade com dart:async
class TimeoutException implements Exception {
  final String? message;
  const TimeoutException([this.message]);
}
