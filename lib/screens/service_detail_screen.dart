import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/reviews_service.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceModel service;
  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _DetailState();
}

class _DetailState extends State<ServiceDetailScreen> {
  bool _fav = false;
  bool _favLoading = true;

  List<ReviewModel> _reviews = [];
  ReviewModel? _myReview;
  bool _reviewsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFav();
    _loadReviews();
  }

  Future<void> _loadFav() async {
    final ids = await FavoritesService().getFavoriteIds();
    if (mounted) setState(() { _fav = ids.contains(widget.service.id); _favLoading = false; });
  }

  Future<void> _loadReviews() async {
    final results = await Future.wait([
      ReviewsService().getReviews(widget.service.id),
      ReviewsService().getMyReview(widget.service.id),
    ]);
    if (!mounted) return;
    setState(() {
      _reviews = results[0] as List<ReviewModel>;
      _myReview = results[1] as ReviewModel?;
      _reviewsLoading = false;
    });
  }

  double get _avgRating {
    if (_reviews.isEmpty) return widget.service.rating;
    return _reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length;
  }

  Future<void> _toggleFav() async {
    if (_fav) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Remover favorito?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: Text('Remover "${widget.service.name}" dos favoritos?',
              style: GoogleFonts.poppins(fontSize: 13)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar', style: GoogleFonts.poppins(color: FC.textMid))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: FC.error, minimumSize: const Size(0, 40)),
              child: const Text('Remover'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    final currentFavs = _fav ? {widget.service.id} : <String>{};
    final ok = await FavoritesService().toggle(widget.service, currentFavs);
    if (ok && mounted) setState(() => _fav = !_fav);
  }

  Color get _color {
    switch (widget.service.category) {
      case Cat.vet:     return FC.catVet;
      case Cat.shop:    return FC.catShop;
      case Cat.banho:   return FC.catBanho;
      case Cat.hotel:   return FC.catHotel;
      case Cat.passeio: return FC.catPasseio;
      case Cat.adest:   return FC.catAdest;
      default:          return FC.blue;
    }
  }

  IconData get _icon {
    switch (widget.service.category) {
      case Cat.vet:     return Icons.local_hospital_rounded;
      case Cat.shop:    return Icons.storefront_rounded;
      case Cat.banho:   return Icons.shower_rounded;
      case Cat.hotel:   return Icons.hotel_rounded;
      case Cat.passeio: return Icons.directions_walk_rounded;
      case Cat.adest:   return Icons.school_rounded;
      default:          return Icons.pets;
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: FC.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) { _snack('Não foi possível abrir o link', FC.error); return; }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _onPhone() {
    final raw = widget.service.phone.replaceAll(RegExp(r'\D'), '');
    if (raw.isEmpty) { _snack('Telefone não cadastrado', FC.error); return; }
    _launch('tel:$raw');
  }

  void _onWhatsApp() {
    final src = widget.service.whatsapp.isNotEmpty ? widget.service.whatsapp : widget.service.phone;
    final raw = src.replaceAll(RegExp(r'\D'), '');
    if (raw.isEmpty) { _snack('WhatsApp não cadastrado', FC.error); return; }
    final num = raw.startsWith('55') ? raw : '55$raw';
    _launch('https://wa.me/$num');
  }

  void _onRoute() {
    final s = widget.service;
    _launch('https://www.google.com/maps/dir/?api=1&destination=${s.lat},${s.lng}');
  }

  // ── Review bottom sheet ──────────────────────────────────────────────────────

  void _openReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        serviceName: widget.service.name,
        existing: _myReview,
        onSubmit: _onSubmitReview,
      ),
    );
  }

  Future<void> _onSubmitReview(int rating, String comment) async {
    if (!AuthService().isLoggedIn) {
      _snack('Faça login para avaliar.', FC.error);
      return;
    }
    final error = await ReviewsService().submitReview(
      serviceId: widget.service.id,
      rating: rating,
      comment: comment,
    );
    if (!mounted) return;
    if (error == null) {
      _snack('Avaliação salva!', FC.success);
      _loadReviews();
    } else {
      _snack(error, FC.error);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = widget.service;

    return Scaffold(
      backgroundColor: FC.bg,
      body: CustomScrollView(slivers: [
        // AppBar com foto
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: _color,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_rounded, color: FC.white, size: 22),
            ),
          ),
          actions: [
            GestureDetector(
              onTap: _favLoading ? null : _toggleFav,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                child: _favLoading
                    ? const SizedBox(width: 36, height: 20,
                        child: Center(child: SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: FC.white, strokeWidth: 2))))
                    : DoublePawIcon(size: 20, active: _fav),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              s.photoUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: s.photoUrls[0],
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: _color.withValues(alpha: 0.3),
                              child: Center(child: CircularProgressIndicator(color: _color, strokeWidth: 2))),
                      errorWidget: (_, __, ___) => _heroBg(),
                    )
                  : _heroBg(),
              const DecoratedBox(decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.transparent, Colors.black38],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter))),
              Positioned(
                bottom: 16, right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: s.isCurrentlyOpen ? FC.success : FC.error, borderRadius: BorderRadius.circular(50)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                        decoration: const BoxDecoration(color: FC.white, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(s.isCurrentlyOpen ? 'Aberto agora' : 'Fechado',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: FC.white)),
                  ]),
                ),
              ),
            ]),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Nome + categoria
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(s.name,
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: FC.textDark))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(50)),
                  child: Text(s.category,
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _color)),
                ),
              ]),
              const SizedBox(height: 10),

              // Rating real
              Row(children: [
                Stars(value: _avgRating),
                const SizedBox(width: 8),
                Text(_avgRating.toStringAsFixed(1),
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: FC.textDark)),
                Text(' (${_reviews.length} avaliações)',
                    style: GoogleFonts.poppins(fontSize: 13, color: FC.textMid)),
              ]),
              const SizedBox(height: 8),

              // Endereço + distância
              Row(children: [
                const Icon(Icons.place_rounded, color: FC.textLight, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(s.address,
                    style: GoogleFonts.poppins(fontSize: 13, color: FC.textMid))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: FC.surfaceAlt, borderRadius: BorderRadius.circular(50)),
                  child: Text(s.distLabel,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: FC.textMid)),
                ),
              ]),
              const SizedBox(height: 22),

              // Botões de ação
              Row(children: [
                Expanded(child: ActionBtn(icon: Icons.phone_rounded, label: 'Ligar',
                    color: FC.catVet, onTap: _onPhone)),
                const SizedBox(width: 10),
                Expanded(child: ActionBtn(icon: Icons.chat_rounded, label: 'WhatsApp',
                    color: const Color(0xFF25D366), onTap: _onWhatsApp)),
                const SizedBox(width: 10),
                Expanded(child: ActionBtn(icon: Icons.directions_rounded, label: 'Rota',
                    color: FC.blue, onTap: _onRoute)),
              ]),
              const SizedBox(height: 22),

              const Divider(color: FC.divider),
              const SizedBox(height: 16),

              // Descrição
              Text('Sobre', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: FC.textDark)),
              const SizedBox(height: 8),
              Text(s.description,
                  style: GoogleFonts.poppins(fontSize: 14, color: FC.textMid, height: 1.6)),
              const SizedBox(height: 22),

              // Horários
              if (s.hours.isNotEmpty) ...[
                Text('Horário de funcionamento',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: FC.textDark)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: FC.white, borderRadius: BorderRadius.circular(FR.card), boxShadow: FS.card),
                  child: Column(children: s.sortedHours.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(e.key, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: FC.textDark)),
                      Text(e.value, style: GoogleFonts.poppins(fontSize: 13, color: FC.textMid)),
                    ]),
                  )).toList()),
                ),
                const SizedBox(height: 22),
              ],

              // ── Avaliações ──────────────────────────────────────────────────
              _ReviewsSection(
                reviews: _reviews,
                loading: _reviewsLoading,
                myReview: _myReview,
                avgRating: _avgRating,
                color: _color,
                onAvaliar: _openReviewSheet,
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ]),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        decoration: BoxDecoration(
          color: FC.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _onWhatsApp,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: const Text('Agendar / Entrar em Contato'),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _openReviewSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: FC.white,
              foregroundColor: FC.blue,
              side: const BorderSide(color: FC.blue),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              minimumSize: const Size(0, 48),
            ),
            child: const Icon(Icons.star_rounded, size: 20),
          ),
        ]),
      ),
    );
  }

  Widget _heroBg() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
          colors: [_color, _color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(_icon, color: Colors.white38, size: 72),
      const SizedBox(height: 8),
      Text('Sem foto cadastrada', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13)),
    ]),
  );
}

// ── Seção de avaliações ────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  final List<ReviewModel> reviews;
  final bool loading;
  final ReviewModel? myReview;
  final double avgRating;
  final Color color;
  final VoidCallback onAvaliar;

  const _ReviewsSection({
    required this.reviews,
    required this.loading,
    required this.myReview,
    required this.avgRating,
    required this.color,
    required this.onAvaliar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Avaliações',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: FC.textDark)),
        TextButton.icon(
          onPressed: onAvaliar,
          icon: Icon(myReview != null ? Icons.edit_rounded : Icons.star_rounded,
              size: 15, color: color),
          label: Text(myReview != null ? 'Editar avaliação' : 'Avaliar',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ),
      ]),

      if (loading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        )
      else if (reviews.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('Seja o primeiro a avaliar!',
              style: GoogleFonts.poppins(fontSize: 13, color: FC.textLight))),
        )
      else ...[
        // Média visual
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: FC.white, borderRadius: BorderRadius.circular(FR.card), boxShadow: FS.card),
          child: Row(children: [
            Text(avgRating.toStringAsFixed(1),
                style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w800, color: FC.textDark)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stars(value: avgRating),
                const SizedBox(height: 4),
                Text('${reviews.length} avaliação${reviews.length > 1 ? "ões" : ""}',
                    style: GoogleFonts.poppins(fontSize: 12, color: FC.textMid)),
                const SizedBox(height: 8),
                // Barras de distribuição
                for (final star in [5, 4, 3, 2, 1])
                  _StarBar(star: star, count: reviews.where((r) => r.rating == star).length,
                      total: reviews.length),
              ]),
            ),
          ]),
        ),

        // Lista de reviews
        ...reviews.take(5).map((r) => _ReviewCard(review: r)),

        if (reviews.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(child: Text('+${reviews.length - 5} avaliações',
                style: GoogleFonts.poppins(fontSize: 12, color: FC.textLight))),
          ),
      ],
    ]);
  }
}

class _StarBar extends StatelessWidget {
  final int star;
  final int count;
  final int total;
  const _StarBar({required this.star, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(children: [
        Text('$star', style: GoogleFonts.poppins(fontSize: 10, color: FC.textLight)),
        const SizedBox(width: 4),
        const Icon(Icons.star_rounded, size: 10, color: Color(0xFFF5A623)),
        const SizedBox(width: 6),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: FC.divider,
            valueColor: const AlwaysStoppedAnimation(Color(0xFFF5A623)),
            minHeight: 5,
          ),
        )),
        const SizedBox(width: 6),
        Text('$count', style: GoogleFonts.poppins(fontSize: 10, color: FC.textLight)),
      ]),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'hoje';
    if (diff.inDays < 30) return 'há ${diff.inDays}d';
    if (diff.inDays < 365) return 'há ${(diff.inDays / 30).round()}m';
    return 'há ${(diff.inDays / 365).round()}a';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: FC.white, borderRadius: BorderRadius.circular(FR.card), boxShadow: FS.card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: FC.blueLight,
            backgroundImage: review.userPhotoUrl != null
                ? NetworkImage(review.userPhotoUrl!) : null,
            child: review.userPhotoUrl == null
                ? Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: FC.blue))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(review.userName,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: FC.textDark)),
            Text(_timeAgo(review.createdAt),
                style: GoogleFonts.poppins(fontSize: 11, color: FC.textLight)),
          ])),
          Stars(value: review.rating.toDouble()),
        ]),
        if (review.comment.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(review.comment,
              style: GoogleFonts.poppins(fontSize: 13, color: FC.textMid, height: 1.5)),
        ],
      ]),
    );
  }
}

// ── Bottom sheet para nova/editar avaliação ────────────────────────────────────

class _ReviewSheet extends StatefulWidget {
  final String serviceName;
  final ReviewModel? existing;
  final Future<void> Function(int rating, String comment) onSubmit;

  const _ReviewSheet({required this.serviceName, this.existing, required this.onSubmit});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late int _rating;
  late final TextEditingController _ctrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 0;
    _ctrl = TextEditingController(text: widget.existing?.comment ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecione uma nota de 1 a 5 estrelas.'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _loading = true);
    await widget.onSubmit(_rating, _ctrl.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: const BoxDecoration(
        color: FC.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: FC.divider, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),

        Text(widget.existing != null ? 'Editar avaliação' : 'Sua avaliação',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: FC.textDark)),
        const SizedBox(height: 4),
        Text(widget.serviceName,
            style: GoogleFonts.poppins(fontSize: 13, color: FC.textMid),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 24),

        // Estrelas
        Center(child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) {
          final n = i + 1;
          return GestureDetector(
            onTap: () => setState(() => _rating = n),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                _rating >= n ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 42,
                color: _rating >= n ? const Color(0xFFF5A623) : FC.divider,
              ),
            ),
          );
        }))),
        const SizedBox(height: 8),
        Center(child: Text(
          _rating == 0 ? 'Toque para avaliar' :
          _rating == 1 ? 'Muito ruim' :
          _rating == 2 ? 'Ruim' :
          _rating == 3 ? 'Regular' :
          _rating == 4 ? 'Bom' : 'Excelente!',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600,
              color: _rating > 0 ? const Color(0xFFF5A623) : FC.textLight),
        )),
        const SizedBox(height: 20),

        // Comentário
        TextField(
          controller: _ctrl,
          maxLines: 3,
          maxLength: 280,
          style: GoogleFonts.poppins(fontSize: 14, color: FC.textDark),
          decoration: InputDecoration(
            hintText: 'Conte sua experiência (opcional)…',
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: FC.textLight),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: FC.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: FC.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: FC.blue, width: 1.5)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: FC.white, strokeWidth: 2))
                : Text(widget.existing != null ? 'Salvar alterações' : 'Enviar avaliação',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
