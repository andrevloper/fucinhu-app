import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../services/favorites_service.dart';
import '../services/auth_service.dart';
import 'service_detail_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  // ── Estado de localização ─────────────────────────────────────────
  LocationResult? _location;
  bool _loadingLocation = true;
  String? _locationError;

  // ── Serviços ─────────────────────────────────────────────────────
  List<ServiceModel> _all = [];
  final Set<String> _favs = {};
  String _cat = '';
  String _query = '';

  // ── Foto do tutor ─────────────────────────────────────────────────
  String? _photoUrl;

  static const _cats = [
    {'l': 'Veterinário', 'i': Icons.local_hospital_rounded, 'c': FC.catVet},
    {'l': 'Pet Shop', 'i': Icons.storefront_rounded, 'c': FC.catShop},
    {'l': 'Banho e Tosa', 'i': Icons.shower_rounded, 'c': FC.catBanho},
    {'l': 'Hotel Pet', 'i': Icons.hotel_rounded, 'c': FC.catHotel},
    {'l': 'Passeador', 'i': Icons.directions_walk_rounded, 'c': FC.catPasseio},
    {'l': 'Adestrador', 'i': Icons.school_rounded, 'c': FC.catAdest},
  ];

  @override
  void initState() {
    super.initState();
    FavoritesService.notifier.addListener(_loadFavorites);
    _initLocation();
    _loadFavorites();
    _loadUserPhoto();
  }

  Future<void> _loadUserPhoto() async {
    // Tenta foto do Google imediatamente (sem await)
    final meta = AuthService().currentUser?.userMetadata;
    final quickUrl = (meta?['avatar_url'] ?? meta?['picture']) as String?;
    if (quickUrl != null && mounted) {
      setState(() => _photoUrl = quickUrl);
    }

    // Busca foto do perfil do banco (pode sobrescrever a do Google)
    try {
      final profile = await AuthService().getProfile();
      final dbUrl = profile?['photo_url'] as String?;
      if (dbUrl != null && dbUrl.isNotEmpty && mounted) {
        setState(() => _photoUrl = dbUrl);
      }
    } catch (_) {
      // Falha silenciosa — o avatar do Google já foi exibido acima
    }
  }

  @override
  void dispose() {
    FavoritesService.notifier.removeListener(_loadFavorites);
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final ids = await FavoritesService().getFavoriteIds();
    if (mounted) {
      setState(() => _favs
        ..clear()
        ..addAll(ids));
    }
  }

  // ── Obtém localização real e carrega serviços ──────────────────────
  Future<void> _initLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    final loc = await LocationService().getCurrentLocation();

    if (!mounted) return;

    // Busca serviços REAIS fora do setState (await não pode ser dentro de setState)
    final services = await PlacesService().fetchAll(
      lat: loc.lat,
      lng: loc.lng,
      radiusMeters: 5000,
    );

    if (!mounted) return;

    setState(() {
      _location = loc;
      _loadingLocation = false;
      _locationError = (!loc.isReal && loc.error != null) ? loc.error : null;
      _all = services;
    });
  }

  List<ServiceModel> get _filtered => _all.where((s) {
        final mc = _cat.isEmpty || s.category == _cat;
        final mq = _query.isEmpty ||
            s.name.toLowerCase().contains(_query.toLowerCase()) ||
            s.category.toLowerCase().contains(_query.toLowerCase());
        return mc && mq;
      }).toList();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  // ── Banner de localização ──────────────────────────────────────────
  Widget _locationBanner() {
    if (_loadingLocation) {
      return Container(
        margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: FC.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(color: FC.white, strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text('Obtendo sua localização...',
              style: GoogleFonts.poppins(fontSize: 12, color: FC.white)),
        ]),
      );
    }

    if (_locationError != null) {
      return GestureDetector(
        onTap: _initLocation,
        child: Container(
          margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: FC.warning.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: FC.warning.withValues(alpha: 0.5), width: 1),
          ),
          child: Row(children: [
            const Icon(Icons.location_off_rounded, color: FC.warning, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _locationError!,
                style: GoogleFonts.poppins(fontSize: 11, color: FC.white),
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 8),
            Text('Tentar novamente',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: FC.warning)),
          ]),
        ),
      );
    }

    if (_location != null && _location!.isReal) {
      return const SizedBox.shrink();
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.userName.split(' ').first;

    return Scaffold(
      backgroundColor: FC.bg,
      body: CustomScrollView(slivers: [
        // ── Header azul ─────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: FC.blue,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + botão favoritos
                    Row(children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 44,
                        color: FC.white,
                        colorBlendMode: BlendMode.srcIn,
                        errorBuilder: (_, __, ___) => Text('Fucinho.co',
                            style: GoogleFonts.poppins(
                                color: FC.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const FavoritesScreen(),
                            transitionsBuilder: (_, a, __, child) =>
                                SlideTransition(
                              position: Tween<Offset>(
                                      begin: const Offset(1, 0),
                                      end: Offset.zero)
                                  .animate(CurvedAnimation(
                                      parent: a, curve: Curves.easeOutCubic)),
                              child: child,
                            ),
                            transitionDuration:
                                const Duration(milliseconds: 340),
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: FC.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const CustomPaint(
                                size: Size(30, 30),
                                painter: _PawPainter(color: FC.white),
                              ),
                            ),
                            if (_favs.isNotEmpty)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: FC.warning,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${_favs.length}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Saudação + avatar do tutor
                    Row(
                      children: [
                        _UserAvatar(photoUrl: _photoUrl, size: 46),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$_greeting, $first! 👋',
                                  style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: FC.white)),
                              Text('Que serviço seu pet precisa hoje?',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: FC.white.withValues(alpha: 0.75))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Banner de localização
                    _locationBanner(),

                    // Campo de busca
                    Container(
                      decoration: BoxDecoration(
                        color: FC.white,
                        borderRadius: BorderRadius.circular(FR.pill),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 4),
                      child: Row(children: [
                        const Icon(Icons.search_rounded,
                            color: FC.textLight, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v),
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: FC.textDark),
                            decoration: InputDecoration(
                              hintText: 'Buscar veterinário, banho e tosa...',
                              hintStyle: GoogleFonts.poppins(
                                  fontSize: 13, color: FC.textLight),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() => _query = ''),
                            child: const Icon(Icons.close_rounded,
                                color: FC.textLight, size: 18),
                          ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Indicação Fucinho ────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const CustomPaint(
                    size: Size(20, 20),
                    painter: _PawPainter(color: FC.blue),
                  ),
                  const SizedBox(width: 8),
                  Text('Indicação Fucinho',
                      style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: FC.textDark)),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: FC.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text('Destaque',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: FC.secondary)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('Serviços avaliados e recomendados pela comunidade',
                    style:
                        GoogleFonts.poppins(fontSize: 12, color: FC.textMid)),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // ── Cards Indicação Fucinho (horizontal) ─────────
        SliverToBoxAdapter(
          child: Builder(builder: (ctx) {
            final featured = _all.where((s) => s.isFeatured).toList();
            if (featured.isEmpty && !_loadingLocation) {
              return const SizedBox.shrink();
            }
            return SizedBox(
              height: 160,
              child: featured.isEmpty
                  ? const Center(
                      child: SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: FC.blue, strokeWidth: 2),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                      itemCount: featured.length,
                      itemBuilder: (ctx, i) {
                        final s = featured[i];
                        return _FucinhuPick(
                          service: s,
                          onTap: () => Navigator.push(
                            ctx,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  ServiceDetailScreen(service: s),
                              transitionsBuilder: (_, a, __, child) =>
                                  SlideTransition(
                                position: Tween<Offset>(
                                        begin: const Offset(0, 1),
                                        end: Offset.zero)
                                    .animate(CurvedAnimation(
                                        parent: a, curve: Curves.easeOutCubic)),
                                child: child,
                              ),
                              transitionDuration:
                                  const Duration(milliseconds: 360),
                            ),
                          ),
                        );
                      },
                    ),
            );
          }),
        ),

        // ── Categorias ──────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Categorias',
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: FC.textDark)),
                if (_cat.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _cat = ''),
                    child: Text('Ver todos',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: FC.blue)),
                  ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: 108,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
              itemCount: _cats.length,
              itemBuilder: (_, i) {
                final c = _cats[i];
                final label = c['l'] as String;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: CatBadge(
                    label: label,
                    icon: c['i'] as IconData,
                    color: c['c'] as Color,
                    selected: _cat == label,
                    onTap: () =>
                        setState(() => _cat = _cat == label ? '' : label),
                  ),
                );
              },
            ),
          ),
        ),

        // ── Título da lista ─────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _cat.isEmpty ? 'Serviços próximos' : _cat,
                  style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: FC.textDark),
                ),
                if (!_loadingLocation)
                  Text('${_filtered.length} encontrados',
                      style:
                          GoogleFonts.poppins(fontSize: 12, color: FC.textMid)),
              ],
            ),
          ),
        ),

        // ── Loading / lista ─────────────────────────────
        if (_loadingLocation)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(children: [
                const CircularProgressIndicator(color: FC.blue),
                const SizedBox(height: 16),
                Text('Buscando serviços próximos...',
                    style:
                        GoogleFonts.poppins(color: FC.textMid, fontSize: 13)),
              ]),
            ),
          )
        else if (_filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [
                const Icon(Icons.search_off_rounded,
                    color: FC.textLight, size: 48),
                const SizedBox(height: 12),
                Text('Nenhum resultado',
                    style: GoogleFonts.poppins(color: FC.textMid)),
              ]),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final s = _filtered[i];
                  return ServiceCard(
                    service: s,
                    isFav: _favs.contains(s.id),
                    onFav: () async {
                      final wasFav = _favs.contains(s.id);
                      final ok = await FavoritesService().toggle(s, _favs);
                      if (ok && mounted) {
                        setState(() {
                          if (wasFav) {
                            _favs.remove(s.id);
                          } else {
                            _favs.add(s.id);
                          }
                        });
                      }
                    },
                    onTap: () => Navigator.push(
                      ctx,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) =>
                            ServiceDetailScreen(service: s),
                        transitionsBuilder: (_, a, __, child) =>
                            SlideTransition(
                          position: Tween<Offset>(
                                  begin: const Offset(0, 1), end: Offset.zero)
                              .animate(CurvedAnimation(
                                  parent: a, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                        transitionDuration: const Duration(milliseconds: 360),
                      ),
                    ),
                  );
                },
                childCount: _filtered.length,
              ),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// Avatar circular do tutor
// ─────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;
  const _UserAvatar({required this.photoUrl, this.size = 46});

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _Fallback(radius: radius),
          errorWidget: (_, __, ___) => _Fallback(radius: radius),
        ),
      );
    }
    return _Fallback(radius: radius);
  }
}

class _Fallback extends StatelessWidget {
  final double radius;
  const _Fallback({required this.radius});

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: FC.white.withValues(alpha: 0.25),
        child: Icon(Icons.person_rounded,
            color: FC.white, size: radius * 1.1),
      );
}

// ─────────────────────────────────────────
// Pata (reutilizável nesta tela)
// ─────────────────────────────────────────
class _PawPainter extends CustomPainter {
  final Color color;
  const _PawPainter({required this.color});

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawOval(
        Rect.fromLTWH(
            s.width * 0.18, s.height * 0.42, s.width * 0.64, s.height * 0.52),
        p);
    canvas.drawOval(
        Rect.fromLTWH(
            s.width * 0.35, s.height * 0.04, s.width * 0.30, s.height * 0.36),
        p);
    canvas.drawOval(
        Rect.fromLTWH(
            s.width * 0.08, s.height * 0.14, s.width * 0.24, s.height * 0.30),
        p);
    canvas.drawOval(
        Rect.fromLTWH(
            s.width * 0.68, s.height * 0.14, s.width * 0.24, s.height * 0.30),
        p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────
// Card "Indicação Fucinho" (horizontal)
// ─────────────────────────────────────────
class _FucinhuPick extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _FucinhuPick({required this.service, required this.onTap});

  Color get _color {
    switch (service.category) {
      case Cat.vet:
        return FC.catVet;
      case Cat.shop:
        return FC.catShop;
      case Cat.banho:
        return FC.catBanho;
      case Cat.hotel:
        return FC.catHotel;
      case Cat.passeio:
        return FC.catPasseio;
      case Cat.adest:
        return FC.catAdest;
      default:
        return FC.blue;
    }
  }

  IconData get _icon {
    switch (service.category) {
      case Cat.vet:
        return Icons.local_hospital_rounded;
      case Cat.shop:
        return Icons.storefront_rounded;
      case Cat.banho:
        return Icons.shower_rounded;
      case Cat.hotel:
        return Icons.hotel_rounded;
      case Cat.passeio:
        return Icons.directions_walk_rounded;
      case Cat.adest:
        return Icons.school_rounded;
      default:
        return Icons.pets;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: FC.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: _color.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem / ícone
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Container(
                height: 72,
                width: double.infinity,
                color: _color.withValues(alpha: 0.12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(_icon, color: _color, size: 34),
                    // Badge pata "Fucinho Pick"
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: FC.blue,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const CustomPaint(
                            size: Size(10, 10),
                            painter: _PawPainter(color: FC.white),
                          ),
                          const SizedBox(width: 3),
                          Text('Pick',
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: FC.white)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: FC.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: FC.warning, size: 12),
                    const SizedBox(width: 2),
                    Text(service.rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: FC.textDark)),
                    const SizedBox(width: 4),
                    Text('· ${service.distLabel}',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: FC.textLight)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
