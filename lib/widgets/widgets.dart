import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

// ─────────────────────────────────────────
// LOGO FUCINHO
// ─────────────────────────────────────────
class FucinhuLogo extends StatelessWidget {
  final Color color;
  // height é a altura; internamente converte para width proporcional
  // O logo tem proporção 924×468 ≈ 2:1, então width ≈ height * 2
  final double height;

  const FucinhuLogo({super.key, this.color = FC.white, this.height = 36});

  @override
  Widget build(BuildContext context) {
    // width proporcional: logo original 924×468 → ratio 1.97
    final logoWidth = height * 1.97;
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      width: logoWidth,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      errorBuilder: (_, __, ___) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pets, color: color, size: height * 0.7),
          const SizedBox(width: 6),
          Text(
            'Fucinho.co',
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: height * 0.55,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// CAMPO PILL (igual ao protótipo)
// ─────────────────────────────────────────
class PillField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final void Function(String)? onChanged;

  const PillField({
    super.key,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w500, color: FC.blue),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
      ),
    );
  }
}

// ─────────────────────────────────────────
// BOTÃO PILL AZUL
// ─────────────────────────────────────────
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  final bool loading;
  final Color? color;
  final Color? foregroundColor;

  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.outlined = false,
    this.loading = false,
    this.color,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: FC.white))
        : Text(label);

    if (outlined) {
      return OutlinedButton(onPressed: loading ? null : onTap, child: child);
    }
    return ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? FC.blue,
        foregroundColor: foregroundColor ?? FC.white,
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────
// BOTÃO SELECIONÁVEL PILL (tipo/espécie pet)
// ─────────────────────────────────────────
class PillSelectButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PillSelectButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: selected ? FC.blue : FC.white,
          border: Border.all(color: FC.blue, width: selected ? 2 : 1.5),
          borderRadius: BorderRadius.circular(FR.pill),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selected ? FC.white : FC.blue,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// BOTÃO GOOGLE
// ─────────────────────────────────────────
class GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const GoogleButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FR.pill)),
        side: const BorderSide(color: FC.divider, width: 1.5),
        backgroundColor: FC.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                Color(0xFF4285F4),
                Color(0xFF34A853),
                Color(0xFFFBBC05),
                Color(0xFFEA4335),
                Color(0xFF4285F4),
              ]),
            ),
            child: Center(
              child: Text('G',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: FC.white)),
            ),
          ),
          const SizedBox(width: 10),
          Text('Entrar com Google',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FC.textDark)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// OR DIVIDER
// ─────────────────────────────────────────
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider(color: FC.divider)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('ou',
            style: GoogleFonts.poppins(fontSize: 12, color: FC.textLight)),
      ),
      const Expanded(child: Divider(color: FC.divider)),
    ]);
  }
}

// ─────────────────────────────────────────
// CATEGORY BADGE
// ─────────────────────────────────────────
class CatBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const CatBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : FC.white,
          borderRadius: BorderRadius.circular(FR.card),
          border: Border.all(color: selected ? color : FC.divider, width: 1.5),
          boxShadow: selected ? FS.card : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? FC.white.withValues(alpha: 0.22)
                    : color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: selected ? FC.white : color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? FC.white : FC.textDark,
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SERVICE CARD
// ─────────────────────────────────────────
class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;
  final VoidCallback? onFav;
  final bool isFav;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    this.onFav,
    this.isFav = false,
  });

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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: FC.white,
          borderRadius: BorderRadius.circular(FR.card),
          boxShadow: FS.card,
        ),
        child: Row(
          children: [
            // Foto / ícone
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(FR.card)),
              child: SizedBox(
                width: 96,
                height: 96,
                child: service.photoUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: service.photoUrls[0],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: _color.withValues(alpha: 0.12),
                          child: Center(child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: _color, strokeWidth: 2))),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: _color.withValues(alpha: 0.12),
                          child: Icon(_icon, color: _color, size: 38),
                        ),
                      )
                    : Container(
                        color: _color.withValues(alpha: 0.12),
                        child: Icon(_icon, color: _color, size: 38),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(service.name,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: FC.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      GestureDetector(
                        onTap: onFav,
                        child: DoublePawIcon(size: 20, active: isFav),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    // Badge categoria
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(service.category,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _color)),
                    ),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.star_rounded,
                          color: FC.warning, size: 13),
                      const SizedBox(width: 3),
                      Text(service.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: FC.textDark)),
                      Text(' (${service.reviewCount})',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: FC.textLight)),
                      const Spacer(),
                      const Icon(Icons.place_rounded,
                          color: FC.textLight, size: 12),
                      const SizedBox(width: 2),
                      Text(service.distLabel,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: FC.textLight)),
                      const SizedBox(width: 6),
                      // Aberto/Fechado
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: service.isCurrentlyOpen
                              ? FC.success.withValues(alpha: 0.12)
                              : FC.error.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          service.isCurrentlyOpen ? 'Aberto' : 'Fechado',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: service.isCurrentlyOpen ? FC.success : FC.error,
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// PET CARD
// ─────────────────────────────────────────
class PetCard extends StatelessWidget {
  final PetModel pet;
  final VoidCallback? onDelete;
  const PetCard({super.key, required this.pet, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FC.white,
        borderRadius: BorderRadius.circular(FR.card),
        boxShadow: FS.card,
      ),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration:
              const BoxDecoration(color: FC.blueLight, shape: BoxShape.circle),
          child: Center(
              child:
                  Text(pet.speciesEmoji, style: const TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pet.name,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: FC.textDark)),
              Text('${pet.breed} · ${pet.ageLabel}',
                  style: GoogleFonts.poppins(fontSize: 12, color: FC.textMid)),
            ],
          ),
        ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: FC.error, size: 20),
            onPressed: onDelete,
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// LOADING OVERLAY
// ─────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool loading;
  final Widget child;
  const LoadingOverlay({super.key, required this.loading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      if (loading)
        Container(
          color: Colors.black26,
          child: const Center(child: CircularProgressIndicator(color: FC.blue)),
        ),
    ]);
  }
}

// ─────────────────────────────────────────
// RATING STARS
// ─────────────────────────────────────────
class Stars extends StatelessWidget {
  final double value;
  final double size;
  const Stars({super.key, required this.value, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < value.floor()) {
          return Icon(Icons.star_rounded, color: FC.warning, size: size);
        }
        if (i < value) {
          return Icon(Icons.star_half_rounded, color: FC.warning, size: size);
        }
        return Icon(Icons.star_outline_rounded, color: FC.warning, size: size);
      }),
    );
  }
}

// ─────────────────────────────────────────
// DOUBLE PAW ICON (botão de favorito)
// ─────────────────────────────────────────
class DoublePawIcon extends StatelessWidget {
  final double size;
  final bool active;
  const DoublePawIcon({super.key, required this.size, this.active = false});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size * 1.8, size),
        painter: _DoublePawPainter(active: active),
      );
}

class _DoublePawPainter extends CustomPainter {
  final bool active;
  const _DoublePawPainter({required this.active});

  @override
  void paint(Canvas canvas, Size s) {
    final color = active ? FC.secondary : FC.textLight;
    final p = Paint()..color = color..style = PaintingStyle.fill;
    final pw = s.height * 0.68;
    final ph = s.height * 0.68;

    // Pata esquerda — cima-esquerda (primeira, alta)
    canvas.save();
    canvas.translate(s.width * 0.26, s.height * 0.38);
    canvas.rotate(-0.22);
    canvas.translate(-pw / 2, -ph / 2);
    _paw(canvas, p, pw, ph);
    canvas.restore();

    // Pata direita — baixo-direita (segunda, baixa)
    canvas.save();
    canvas.translate(s.width * 0.74, s.height * 0.62);
    canvas.rotate(0.22);
    canvas.translate(-pw / 2, -ph / 2);
    _paw(canvas, p, pw, ph);
    canvas.restore();
  }

  void _paw(Canvas canvas, Paint p, double w, double h) {
    canvas.drawOval(Rect.fromLTWH(w * 0.18, h * 0.42, w * 0.64, h * 0.52), p);
    canvas.drawOval(Rect.fromLTWH(w * 0.35, h * 0.04, w * 0.30, h * 0.36), p);
    canvas.drawOval(Rect.fromLTWH(w * 0.08, h * 0.14, w * 0.24, h * 0.30), p);
    canvas.drawOval(Rect.fromLTWH(w * 0.68, h * 0.14, w * 0.24, h * 0.30), p);
  }

  @override
  bool shouldRepaint(_DoublePawPainter old) => old.active != active;
}

// ─────────────────────────────────────────
// ACTION BUTTON (ligar / whatsapp / rota)
// ─────────────────────────────────────────
class ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(FR.sm),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}
