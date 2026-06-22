import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/pet_service.dart';

import 'login_screen.dart';
import 'favorites_screen.dart';
import 'pets_list_screen.dart';
import 'profile_edit_screen.dart';
import 'about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  int _favCount = 0;
  int _petCount = 0;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    FavoritesService.notifier.addListener(_reloadFavCount);

    _load();
  }

  @override
  void dispose() {
    FavoritesService.notifier.removeListener(_reloadFavCount);
    super.dispose();
  }

  Future<void> _reloadFavCount() async {
    final ids = await FavoritesService().getFavoriteIds();

    if (!mounted) return;

    setState(() {
      _favCount = ids.length;
    });
  }

  Future<void> _load() async {
    setState(() => _loadError = null);

    String? err;

    // Profile — se falhar, guarda o erro mas continua
    try {
      final profile = await AuthService().getProfile();
      if (!mounted) return;
      if (profile != null && profile['photo_url'] != null) {
        profile['photo_url'] =
            '${profile['photo_url']}?v=${DateTime.now().millisecondsSinceEpoch}';
      }
      setState(() => _profile = profile);
    } catch (e) {
      err = e.toString();
    }

    // Favoritos — tem catch próprio, nunca lança
    final favs = await FavoritesService().getFavoriteIds();
    if (!mounted) return;
    setState(() => _favCount = favs.length);

    // Pets — se falhar, guarda o erro mas continua
    try {
      final pets = await PetService().getPets();
      if (!mounted) return;
      setState(() => _petCount = pets.length);
    } catch (e) {
      err ??= e.toString();
    }

    if (!mounted) return;
    if (err != null) setState(() => _loadError = err);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FR.xl),
        ),
        title: Text(
          'Sair da conta',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Deseja realmente sair?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                color: FC.textMid,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FC.error,
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    final name = _profile?['name'] as String? ?? AuthService().displayName;

    final phone = _profile?['phone'] as String? ?? '';

    final email = user?.email ?? '';

    final photoUrl = _profile?['photo_url'] as String?;

    return Scaffold(
      backgroundColor: FC.bg,
      body: RefreshIndicator(
        color: FC.blue,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ───────────────── HEADER ─────────────────

            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: FC.blue,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      22,
                      20,
                      22,
                      32,
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 32,
                            color: FC.white,
                            colorBlendMode: BlendMode.srcIn,
                            errorBuilder: (_, __, ___) => Text(
                              'Fucinho.co',
                              style: GoogleFonts.poppins(
                                color: FC.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ───────────────── AVATAR ─────────────────

                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final updated = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileEditScreen(
                                      profile: _profile ?? {},
                                    ),
                                  ),
                                );

                                if (updated == true) {
                                  await _load();
                                }
                              },
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: FC.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: FC.white,
                                    width: 3,
                                  ),
                                ),
                                child: photoUrl != null && photoUrl.isNotEmpty
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          key: ValueKey(photoUrl),
                                          imageUrl: photoUrl,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 400,
                                          maxWidthDiskCache: 400,
                                          fadeInDuration: Duration.zero,
                                          placeholder: (_, __) => const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          errorWidget: (_, __, ___) =>
                                              const Icon(
                                            Icons.person_rounded,
                                            color: FC.white,
                                            size: 46,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person_rounded,
                                        color: FC.white,
                                        size: 46,
                                      ),
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: FC.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: FC.blue,
                                size: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: FC.white,
                          ),
                        ),

                        Text(
                          email,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: FC.textOnBlue2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ───────────────── ERRO DE CARREGAMENTO ─────────────────

            if (_loadError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: FC.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(FR.card),
                      border: Border.all(color: FC.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.cloud_off_rounded, color: FC.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _loadError!,
                          style: GoogleFonts.poppins(fontSize: 11, color: FC.error),
                        ),
                      ),
                      TextButton(
                        onPressed: _load,
                        child: Text('Tentar', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: FC.error)),
                      ),
                    ]),
                  ),
                ),
              ),

            // ───────────────── CARD PERFIL ─────────────────

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  20,
                  22,
                  0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: FC.white,
                    borderRadius: BorderRadius.circular(FR.card),
                    boxShadow: FS.card,
                  ),
                  child: Column(
                    children: [
                      _ContactRow(
                        icon: Icons.person_rounded,
                        label: 'Nome',
                        value: name,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          color: FC.divider,
                          height: 1,
                        ),
                      ),
                      _ContactRow(
                        icon: Icons.email_rounded,
                        label: 'E-mail',
                        value: email,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          color: FC.divider,
                          height: 1,
                        ),
                      ),
                      _ContactRow(
                        icon: Icons.phone_rounded,
                        label: 'Telefone',
                        value: phone.isNotEmpty ? phone : 'Não informado',
                        dimmed: phone.isEmpty,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ───────────────── MENU ─────────────────

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  20,
                  22,
                  100,
                ),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.edit_rounded,
                      label: 'Editar meus dados',
                      onTap: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileEditScreen(
                              profile: _profile ?? {},
                            ),
                          ),
                        );
                        if (updated == true) await _load();
                      },
                    ),
                    _MenuItem(
                      icon: Icons.pets_rounded,
                      label: 'Meus Pets',
                      badge: _petCount,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PetsListScreen(),
                        ),
                      ).then((_) => _load()),
                    ),
                    _MenuItem(
                      icon: Icons.favorite_rounded,
                      label: 'Serviços favoritos',
                      badge: _favCount,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FavoritesScreen(),
                        ),
                      ).then((_) => _load()),
                    ),
                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      label: 'Sobre o aplicativo',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      label: 'Sair da conta',
                      color: FC.error,
                      onTap: _logout,
                    ),
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

// ───────────────── CONTACT ROW ─────────────────

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool dimmed;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: FC.blueLight,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: FC.blue,
            size: 19,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: FC.textLight,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: dimmed ? FC.textLight : FC.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────── MENU ITEM ─────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = FC.textDark,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: FC.divider,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (badge != null && badge! > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: FC.blue,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  '$badge',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: FC.white,
                  ),
                ),
              ),
            const Icon(
              Icons.chevron_right_rounded,
              color: FC.textLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
