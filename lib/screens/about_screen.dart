import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FC.bg,
      body: CustomScrollView(
        slivers: [
          // ── HEADER ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: FC.blue,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Botão voltar
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: FC.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Logo
                    Image.asset(
                      'assets/images/logo.png',
                      height: 72,
                      color: FC.white,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (_, __, ___) => Text(
                        'Fucinho.co',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: FC.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Versão 1.0.0',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: FC.textOnBlue2,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),

          // ── DESCRIÇÃO ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: FC.white,
                  borderRadius: BorderRadius.circular(FR.card),
                  boxShadow: FS.card,
                ),
                child: Text(
                  'O Fucinho.co conecta tutores de pets a serviços de qualidade perto de você — veterinários, pet shops, banho e tosa, hotéis, passeadores e adestramento.\n\nEncontre, avalie e favorite os melhores estabelecimentos da sua região com facilidade.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: FC.textMid,
                    height: 1.65,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // ── INFORMAÇÕES ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: FC.white,
                  borderRadius: BorderRadius.circular(FR.card),
                  boxShadow: FS.card,
                ),
                child: Column(
                  children: [
                    const _InfoRow(
                      icon: Icons.code_rounded,
                      label: 'Desenvolvido por',
                      value: 'Equipe Fucinho.co',
                    ),
                    const Divider(height: 1, color: FC.divider, indent: 54),
                    _InfoRow(
                      icon: Icons.email_rounded,
                      label: 'Contato',
                      value: 'contato@fucinho.co',
                      onTap: () => _launch('mailto:contato@fucinho.co'),
                    ),
                    const Divider(height: 1, color: FC.divider, indent: 54),
                    _InfoRow(
                      icon: Icons.language_rounded,
                      label: 'Site',
                      value: 'fucinho.co',
                      onTap: () => _launch('https://fucinho.co'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── LINKS LEGAIS ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: FC.white,
                  borderRadius: BorderRadius.circular(FR.card),
                  boxShadow: FS.card,
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.privacy_tip_rounded,
                      label: 'Política de Privacidade',
                      value: '',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: FC.textLight, size: 20),
                      onTap: () => _launch('https://fucinho.co/privacidade'),
                    ),
                    const Divider(height: 1, color: FC.divider, indent: 54),
                    _InfoRow(
                      icon: Icons.description_rounded,
                      label: 'Termos de Uso',
                      value: '',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: FC.textLight, size: 20),
                      onTap: () => _launch('https://fucinho.co/termos'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── RODAPÉ ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 40),
              child: Text(
                '© 2026 Fucinho.co — Feito com ❤️ para tutores de pets',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: FC.textLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FR.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: FC.blueLight,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: FC.blue, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FC.textLight,
                    ),
                  ),
                  if (value.isNotEmpty)
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: FC.textDark,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
