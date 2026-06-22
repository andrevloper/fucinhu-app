import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/favorites_service.dart';
import 'service_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesState();
}

class _FavoritesState extends State<FavoritesScreen> {
  List<ServiceModel> _favServices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final favs = await FavoritesService().getFavorites();
    if (mounted) setState(() { _favServices = favs; _loading = false; });
  }

  Color _catColor(String cat) {
    switch (cat) {
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

  IconData _catIcon(String cat) {
    switch (cat) {
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
    final favs = _favServices;

    return Scaffold(
      backgroundColor: FC.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FC.blue))
          : Column(children: [
        // ── Header azul ──────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: FC.blue,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back,
                          color: FC.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Image.asset('assets/images/logo.png',
                        height: 32,
                        color: FC.white,
                        colorBlendMode: BlendMode.srcIn,
                        errorBuilder: (_, __, ___) => Text('Fucinho.co',
                            style: GoogleFonts.poppins(
                                color: FC.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18))),
                  ]),
                  const SizedBox(height: 18),
                  Row(children: [
                    // ── Ícone de PATA ──────────────────────────────
                    const _PawIcon(size: 28, color: FC.white),
                    const SizedBox(width: 10),
                    Text('Meus Favoritos',
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: FC.white)),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    favs.isEmpty
                        ? 'Nenhum serviço favorito ainda'
                        : '${favs.length} ${favs.length == 1 ? "serviço salvo" : "serviços salvos"}',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: FC.white.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Lista ────────────────────────────────────────────────
        Expanded(
          child: favs.isEmpty
              ? _Empty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                  itemCount: favs.length,
                  itemBuilder: (ctx, i) {
                    final s = favs[i];
                    return _FavCard(
                      service: s,
                      catColor: _catColor(s.category),
                      catIcon: _catIcon(s.category),
                      onRemove: () async {
                        await FavoritesService().removeFavorite(s.id);
                        if (mounted) setState(() => _favServices.removeWhere((f) => f.id == s.id));
                      },
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
                                const Duration(milliseconds: 340),
                          )),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// Ícone de PATA (CustomPainter)
// ─────────────────────────────────────────
class _PawIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _PawIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _PawPainter(color: color));
}

class _PawPainter extends CustomPainter {
  final Color color;
  const _PawPainter({required this.color});

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = s.width;
    final h = s.height;

    // Palma principal
    canvas.drawOval(Rect.fromLTWH(w * 0.18, h * 0.42, w * 0.64, h * 0.52), p);

    // Dedo central (maior)
    canvas.drawOval(Rect.fromLTWH(w * 0.35, h * 0.04, w * 0.30, h * 0.36), p);

    // Dedo esquerdo
    canvas.drawOval(Rect.fromLTWH(w * 0.08, h * 0.14, w * 0.24, h * 0.30), p);

    // Dedo direito
    canvas.drawOval(Rect.fromLTWH(w * 0.68, h * 0.14, w * 0.24, h * 0.30), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────
// Card de favorito
// ─────────────────────────────────────────
class _FavCard extends StatelessWidget {
  final ServiceModel service;
  final Color catColor;
  final IconData catIcon;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _FavCard({
    required this.service,
    required this.catColor,
    required this.catIcon,
    required this.onRemove,
    required this.onTap,
  });

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remover favorito?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Remover "${service.name}" dos favoritos?',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar',
                  style: GoogleFonts.poppins(color: FC.textMid))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: FC.error, minimumSize: const Size(0, 40)),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: FC.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: FC.blue.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(20)),
            child: service.photoUrls.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: service.photoUrls.first,
                    width: 88,
                    height: 96,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _ImgFallback(
                        color: catColor, icon: catIcon),
                    errorWidget: (_, __, ___) => _ImgFallback(
                        color: catColor, icon: catIcon),
                  )
                : _ImgFallback(color: catColor, icon: catIcon),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
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
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(50)),
                    child: Text(service.category,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: catColor)),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: FC.warning, size: 13),
                    const SizedBox(width: 3),
                    Text(service.rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FC.textDark)),
                    Text(' · ${service.distLabel}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: FC.textLight)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: service.isCurrentlyOpen
                            ? FC.success.withValues(alpha: 0.12)
                            : FC.error.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(service.isCurrentlyOpen ? 'Aberto' : 'Fechado',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: service.isCurrentlyOpen ? FC.success : FC.error)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          // ── Pata de favorito (remover) ───────────────────
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => _confirmRemove(context),
              child: const _PawIcon(size: 26, color: FC.error),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Fallback de imagem (ícone da categoria)
// ─────────────────────────────────────────
class _ImgFallback extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _ImgFallback({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: 88,
        height: 96,
        color: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color, size: 36),
      );
}

// ─────────────────────────────────────────
// Estado vazio
// ─────────────────────────────────────────
class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const _PawIcon(size: 72, color: FC.blueLight),
        const SizedBox(height: 20),
        Text('Nenhum favorito ainda',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700, color: FC.textDark)),
        const SizedBox(height: 8),
        Text('Toque na 🐾 em qualquer serviço\npara salvá-lo aqui',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 13, color: FC.textMid, height: 1.5)),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Explorar serviços'),
          ),
        ),
      ]),
    );
  }
}
