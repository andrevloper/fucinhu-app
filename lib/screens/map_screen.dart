import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../services/geocoding_service.dart';
import '../models/models.dart';
import 'service_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapState();
}

class _MapState extends State<MapScreen> {
  late final MapController _mapController;
  LocationResult? _location;
  bool _loadingLoc = true;
  String _filterCat = '';
  double _filterDist = 5.0;
  ServiceModel? _selected;
  bool _showFilter = false;
  bool _showSearch = false;
  List<ServiceModel> _services = [];
  StreamSubscription<LocationResult>? _positionSub;
  LatLng? _searchPin;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initLocation();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() => _loadingLoc = true);
    final loc = await LocationService().getCurrentLocation();
    if (!mounted) return;
    final services = await PlacesService().fetchAll(
      lat: loc.lat,
      lng: loc.lng,
      radiusMeters: 10000,
    );
    if (!mounted) return;
    setState(() {
      _location = loc;
      _services = services;
      _loadingLoc = false;
    });
    _startTracking();
  }

  void _startTracking() {
    _positionSub?.cancel();
    _positionSub = LocationService().positionStream.listen((loc) {
      if (!mounted) return;
      setState(() => _location = loc);
    });
  }

  List<ServiceModel> get _filtered => _location == null
      ? []
      : _services
          .where((s) =>
              (_filterCat.isEmpty || s.category == _filterCat) &&
              s.distanceKm <= _filterDist)
          .toList();

  Color _cc(String cat) {
    switch (cat) {
      case Cat.vet:     return FC.catVet;
      case Cat.shop:    return FC.catShop;
      case Cat.banho:   return FC.catBanho;
      case Cat.hotel:   return FC.catHotel;
      case Cat.passeio: return FC.catPasseio;
      case Cat.adest:   return FC.catAdest;
      default:          return FC.blue;
    }
  }

  void _onSearchLocationSelected(double lat, double lng) {
    setState(() {
      _searchPin = LatLng(lat, lng);
      _showSearch = false;
      _selected = null;
    });
    _mapController.move(LatLng(lat, lng), 15);
    _loadServicesAt(lat, lng);
  }

  void _onSearchServiceSelected(ServiceModel s) {
    setState(() {
      _selected = s;
      _showSearch = false;
      _searchPin = null;
    });
    _mapController.move(LatLng(s.lat, s.lng), 16);
  }

  Future<void> _loadServicesAt(double lat, double lng) async {
    final services = await PlacesService().fetchAll(
      lat: lat,
      lng: lng,
      radiusMeters: 10000,
    );
    if (!mounted) return;
    setState(() => _services = services);
  }

  Future<void> _goToMyLocation() async {
    LocationService().clearCache();
    final loc = await LocationService().getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _location = loc;
      _searchPin = null;
    });
    _mapController.move(LatLng(loc.lat, loc.lng), 15);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [

        // ── MAPA REAL ───────────────────────────────────────────
        if (_loadingLoc)
          const Center(child: CircularProgressIndicator(color: FC.blue))
        else
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_location!.lat, _location!.lng),
              initialZoom: 14,
              minZoom: 5,
              maxZoom: 19,
              onTap: (_, __) {
                if (_selected != null) setState(() => _selected = null);
                if (_showFilter) setState(() => _showFilter = false);
              },
            ),
            children: [
              // Tiles OpenStreetMap — sem API key
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'co.fucinho.app',
                maxNativeZoom: 19,
              ),

              // Marcadores dos serviços
              MarkerLayer(
                markers: _filtered.map((s) {
                  final isSel = _selected?.id == s.id;
                  final color = _cc(s.category);
                  return Marker(
                    point: LatLng(s.lat, s.lng),
                    width: isSel ? 52 : 42,
                    height: isSel ? 60 : 50,
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _selected = _selected?.id == s.id ? null : s),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.all(isSel ? 9 : 6),
                            decoration: BoxDecoration(
                              color: isSel ? color : FC.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: color, width: isSel ? 2.5 : 2),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: isSel ? 18 : 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.pets,
                              color: isSel ? FC.white : color,
                              size: isSel ? 18 : 14,
                            ),
                          ),
                          CustomPaint(
                            size: const Size(12, 7),
                            painter: _PinTip(color: color),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Marcador do usuário
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_location!.lat, _location!.lng),
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: FC.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: FC.white, width: 3),
                        boxShadow: FS.fab,
                      ),
                    ),
                  ),
                ],
              ),

              // Marcador de busca
              if (_searchPin != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _searchPin!,
                      width: 42,
                      height: 50,
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: FC.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: FC.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: FC.error.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: FC.white,
                              size: 14,
                            ),
                          ),
                          const CustomPaint(
                            size: Size(12, 7),
                            painter: _PinTip(color: FC.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // Atribuição OpenStreetMap (obrigatória pelos termos de uso)
              const SimpleAttributionWidget(
                source: Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),

        // ── HEADER ─────────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _showSearch = true;
                      _showFilter = false;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: FC.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: FS.card,
                      ),
                      child: Row(children: [
                        const Icon(Icons.search_rounded,
                            color: FC.textLight, size: 20),
                        const SizedBox(width: 8),
                        Text('Buscar localização ou serviço',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: FC.textLight)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () =>
                      setState(() => _showFilter = !_showFilter),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _showFilter ? FC.blue : FC.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: FS.card,
                    ),
                    child: Icon(Icons.tune_rounded,
                        color:
                            _showFilter ? FC.white : FC.textDark,
                        size: 22),
                  ),
                ),
              ]),
            ),
          ),
        ),

        // ── FILTROS ─────────────────────────────────────────────
        if (_showFilter)
          Positioned(
            top: 80, left: 16, right: 16,
            child: SafeArea(
              child: _FilterPanel(
                cat: _filterCat,
                dist: _filterDist,
                onCat: (v) => setState(() => _filterCat = v),
                onDist: (v) => setState(() => _filterDist = v),
                onClose: () => setState(() => _showFilter = false),
              ),
            ),
          ),

        // ── CARD SELECIONADO ────────────────────────────────────
        if (_selected != null)
          Positioned(
            bottom: 90, left: 16, right: 16,
            child: _SelectedCard(
              service: _selected!,
              onClose: () => setState(() => _selected = null),
              onDetail: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                      ServiceDetailScreen(service: _selected!),
                  transitionsBuilder: (_, a, __, child) =>
                      SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero)
                        .animate(CurvedAnimation(
                            parent: a,
                            curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                  transitionDuration:
                      const Duration(milliseconds: 340),
                ),
              ),
            ),
          ),

        // ── BUSCA ────────────────────────────────────────────────
        if (_showSearch)
          Positioned.fill(
            child: _SearchOverlay(
              services: _services,
              onClose: () => setState(() => _showSearch = false),
              onLocationSelected: _onSearchLocationSelected,
              onServiceSelected: _onSearchServiceSelected,
              onMyLocation: () {
                setState(() => _showSearch = false);
                _goToMyLocation();
              },
            ),
          ),

        // ── FAB — minha localização ─────────────────────────────
        Positioned(
          bottom: 24, right: 16,
          child: FloatingActionButton.small(
            heroTag: null,
            onPressed: _goToMyLocation,
            backgroundColor: FC.white,
            elevation: 4,
            child: const Icon(Icons.my_location_rounded,
                color: FC.blue),
          ),
        ),
      ]),
    );
  }
}

// ── PIN TIP ──────────────────────────────────────────────────────
class _PinTip extends CustomPainter {
  final Color color;
  const _PinTip({required this.color});

  @override
  void paint(Canvas canvas, Size s) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(s.width / 2, s.height)
      ..lineTo(s.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── FILTER PANEL ─────────────────────────────────────────────────
class _FilterPanel extends StatelessWidget {
  final String cat;
  final double dist;
  final void Function(String) onCat;
  final void Function(double) onDist;
  final VoidCallback onClose;

  const _FilterPanel({
    required this.cat,
    required this.dist,
    required this.onCat,
    required this.onDist,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FC.white,
        borderRadius: BorderRadius.circular(FR.xl),
        boxShadow: FS.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Filtros',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close_rounded,
                color: FC.textMid, size: 20),
          ),
        ]),
        const SizedBox(height: 14),
        Text('Categoria',
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FC.textMid)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Chip(
              label: 'Todos',
              selected: cat.isEmpty,
              onTap: () => onCat('')),
          ...Cat.all.map((c) => _Chip(
              label: c,
              selected: cat == c,
              onTap: () => onCat(cat == c ? '' : c))),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Distância',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FC.textMid)),
          Text('${dist.toStringAsFixed(0)} km',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: FC.blue)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: FC.blue,
            inactiveTrackColor: FC.divider,
            thumbColor: FC.blue,
            overlayColor: FC.blue.withValues(alpha: 0.15),
            trackHeight: 3,
          ),
          child: Slider(
            value: dist,
            min: 1,
            max: 20,
            divisions: 19,
            onChanged: onDist,
          ),
        ),
      ]),
    );
  }
}

// ── CHIP ─────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? FC.blue : FC.surfaceAlt,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
              color: selected ? FC.blue : FC.divider),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? FC.white : FC.textDark)),
      ),
    );
  }
}

// ── SEARCH OVERLAY ──────────────────────────────────────────────
class _SearchOverlay extends StatefulWidget {
  final List<ServiceModel> services;
  final VoidCallback onClose;
  final void Function(double lat, double lng) onLocationSelected;
  final void Function(ServiceModel) onServiceSelected;
  final VoidCallback onMyLocation;

  const _SearchOverlay({
    required this.services,
    required this.onClose,
    required this.onLocationSelected,
    required this.onServiceSelected,
    required this.onMyLocation,
  });

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<GeocodingResult> _geoResults = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _geoResults = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await GeocodingService().search(query);
      if (!mounted) return;
      setState(() {
        _geoResults = results;
        _loading = false;
      });
    });
  }

  List<ServiceModel> get _serviceMatches {
    final q = _controller.text.toLowerCase();
    if (q.length < 2) return [];
    return widget.services
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.address.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q))
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final serviceMatches = _serviceMatches;
    final hasResults =
        serviceMatches.isNotEmpty || _geoResults.isNotEmpty;
    final hasQuery = _controller.text.trim().isNotEmpty;

    return Container(
      color: FC.white,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: FC.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: FC.textDark, size: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: FC.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    const Icon(Icons.search_rounded,
                        color: FC.textLight, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        onChanged: _onChanged,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: FC.textDark),
                        decoration: InputDecoration(
                          hintText: 'Endereço, bairro ou serviço...',
                          hintStyle: GoogleFonts.poppins(
                              fontSize: 13, color: FC.textLight),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          filled: false,
                        ),
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _controller.clear();
                          _onChanged('');
                        },
                        child: const Icon(Icons.close_rounded,
                            color: FC.textLight, size: 18),
                      ),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: widget.onMyLocation,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: FC.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.my_location_rounded,
                        color: FC.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Usar minha localização atual',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: FC.blue)),
                ]),
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                    color: FC.blue, strokeWidth: 2),
              ),
            )
          else if (hasQuery && !hasResults)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(children: [
                const Icon(Icons.search_off_rounded,
                    color: FC.textLight, size: 40),
                const SizedBox(height: 10),
                Text('Nenhum resultado encontrado',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: FC.textMid)),
              ]),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (serviceMatches.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 4, bottom: 8),
                      child: Text('Serviços',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: FC.textMid)),
                    ),
                    ...serviceMatches.map((s) => _SearchTile(
                          icon: Icons.pets_rounded,
                          iconColor: FC.blue,
                          title: s.name,
                          subtitle:
                              '${s.category} · ${s.distLabel}',
                          onTap: () =>
                              widget.onServiceSelected(s),
                        )),
                  ],
                  if (_geoResults.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 12, bottom: 8),
                      child: Text('Localizações',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: FC.textMid)),
                    ),
                    ..._geoResults.map((r) {
                      final parts = r.displayName.split(',');
                      final title = parts.first.trim();
                      final subtitle = parts.length > 1
                          ? parts.sublist(1).join(',').trim()
                          : '';
                      return _SearchTile(
                        icon: Icons.location_on_rounded,
                        iconColor: FC.error,
                        title: title,
                        subtitle: subtitle,
                        onTap: () => widget.onLocationSelected(
                            r.lat, r.lng),
                      );
                    }),
                  ],
                  if (!hasQuery)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Column(children: [
                        Icon(Icons.place_rounded,
                            color: FC.textLight.withValues(alpha: 0.5),
                            size: 48),
                        const SizedBox(height: 10),
                        Text(
                          'Pesquise por endereço, bairro,\ncidade ou nome de serviço',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: FC.textLight),
                        ),
                      ]),
                    ),
                ],
              ),
            ),
        ]),
      ),
    );
  }
}

class _SearchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SearchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FC.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: FC.textMid),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.north_west_rounded,
              color: FC.textLight, size: 16),
        ]),
      ),
    );
  }
}

// ── SELECTED CARD ────────────────────────────────────────────────
class _SelectedCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onClose;
  final VoidCallback onDetail;
  const _SelectedCard(
      {required this.service,
      required this.onClose,
      required this.onDetail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: FC.white,
          borderRadius: BorderRadius.circular(FR.xl),
          boxShadow: FS.card),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
              color: FC.blueLight,
              borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.pets, color: FC.blue, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: FC.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Row(children: [
                  const Icon(Icons.star_rounded,
                      color: FC.warning, size: 13),
                  const SizedBox(width: 3),
                  Text(service.rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: FC.textDark)),
                  Text(' · ${service.distLabel}',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: FC.textMid)),
                ]),
              ]),
        ),
        Column(children: [
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close_rounded,
                color: FC.textLight, size: 18),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onDetail,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: FC.blue,
                  borderRadius: BorderRadius.circular(50)),
              child: Text('Ver mais',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FC.white)),
            ),
          ),
        ]),
      ]),
    );
  }
}
