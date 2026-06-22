import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/establishments_service.dart';
import '../../theme/app_theme.dart';
import 'establishment_form_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: FC.bg,
      body: Row(
        children: [
          _Sidebar(index: _index, onSelect: (i) => setState(() => _index = i), wide: wide),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                _DashboardTab(),
                _UsersTab(),
                _PetsTab(),
                _FavoritesTab(),
                _EstabelecimentosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final bool wide;

  const _Sidebar({required this.index, required this.onSelect, required this.wide});

  static const _nav = [
    (Icons.dashboard_rounded, 'Dashboard'),
    (Icons.people_rounded, 'Usuários'),
    (Icons.pets_rounded, 'Pets'),
    (Icons.favorite_rounded, 'Favoritos'),
    (Icons.storefront_rounded, 'Estabelecimentos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? 220 : 72,
      color: FC.blue,
      child: Column(
        children: [
          const SizedBox(height: 32),
          if (wide)
            Column(children: [
              const Icon(Icons.pets, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text('Fucinho Admin',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 24),
            ])
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Icon(Icons.pets, color: Colors.white, size: 28),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _nav.length,
              itemBuilder: (_, i) {
                final (icon, label) = _nav[i];
                final sel = index == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSelect(i),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: wide ? 14 : 0, vertical: 13),
                      decoration: BoxDecoration(
                        color: sel
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: wide
                          ? Row(children: [
                              Icon(icon, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Text(label,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                    color: Colors.white,
                                  )),
                            ])
                          : Center(child: Icon(icon, color: Colors.white, size: 22)),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white70),
              tooltip: 'Sair',
              onPressed: () => AuthService().signOut(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  AdminStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats = await AdminService().getStats();
    if (!mounted) return;
    setState(() { _stats = stats; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: FC.blue));
    final s = _stats!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(title: 'Dashboard', onRefresh: _load),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                icon: Icons.people_rounded,
                color: FC.catVet,
                label: 'Usuários',
                value: '${s.totalUsers}',
              ),
              _StatCard(
                icon: Icons.pets_rounded,
                color: FC.catShop,
                label: 'Pets',
                value: '${s.totalPets}',
              ),
              _StatCard(
                icon: Icons.favorite_rounded,
                color: FC.secondary,
                label: 'Favoritos',
                value: '${s.totalFavorites}',
              ),
              _StatCard(
                icon: Icons.storefront_rounded,
                color: FC.catAdest,
                label: 'Estabelecimentos',
                value: '${s.totalEstablishments}',
              ),
            ],
          ),
          if (s.petsBySpecies.isNotEmpty) ...[
            const SizedBox(height: 32),
            const _SectionTitle(text: 'Pets por espécie'),
            const SizedBox(height: 12),
            ...s.petsBySpecies.entries.map((e) {
              final total = s.totalPets > 0 ? s.totalPets : 1;
              final pct = e.value / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SpeciesBar(label: e.key, count: e.value, pct: pct),
              );
            }),
          ],
          if (s.topServices.isNotEmpty) ...[
            const SizedBox(height: 32),
            const _SectionTitle(text: 'Serviços mais favoritados'),
            const SizedBox(height: 12),
            ...s.topServices.take(5).map((sv) => _TopServiceRow(service: sv)),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FR.card),
        boxShadow: FS.card,
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.w800, color: FC.textDark)),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 12, color: FC.textLight)),
          ],
        ),
      ]),
    );
  }
}

class _SpeciesBar extends StatelessWidget {
  final String label;
  final int count;
  final double pct;
  const _SpeciesBar({required this.label, required this.count, required this.pct});

  String get emoji => label == 'Cachorro' ? '🐶' : label == 'Gato' ? '🐱' : '🐾';

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 32, child: Text(emoji, style: const TextStyle(fontSize: 20))),
      const SizedBox(width: 8),
      SizedBox(
        width: 80,
        child: Text(label,
            style: GoogleFonts.poppins(fontSize: 13, color: FC.textDark)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            color: FC.blue,
            backgroundColor: FC.blueLight,
          ),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 30,
        child: Text('$count',
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700, color: FC.textDark)),
      ),
    ]);
  }
}

class _TopServiceRow extends StatelessWidget {
  final PopularService service;
  const _TopServiceRow({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FR.sm),
        border: Border.all(color: FC.divider),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: FC.blueLight,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(service.serviceCategory,
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: FC.blue)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(service.serviceName,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: FC.textDark),
              overflow: TextOverflow.ellipsis),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: FC.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text('${service.count} favs',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: FC.secondary)),
        ),
      ]),
    );
  }
}

// ── Users ─────────────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<AdminProfile> _all = [];
  List<AdminProfile> _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final users = await AdminService().getUsers();
    if (!mounted) return;
    setState(() { _all = users; _loading = false; _filter(); });
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((u) => u.name.toLowerCase().contains(q) || u.phone.contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: _PageHeader(title: 'Usuários (${_all.length})', onRefresh: _load),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _SearchField(controller: _search, hint: 'Buscar por nome ou telefone'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: FC.blue))
              : _filtered.isEmpty
                  ? const _EmptyState(label: 'Nenhum usuário encontrado')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _UserRow(user: _filtered[i]),
                    ),
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  final AdminProfile user;
  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FR.card),
        boxShadow: FS.card,
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: FC.blueLight,
          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          child: user.photoUrl == null
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w700, color: FC.blue),
                )
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(user.name.isNotEmpty ? user.name : 'Sem nome',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700, color: FC.textDark)),
                if (user.isAdmin) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: FC.blue,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text('Admin',
                        style: GoogleFonts.poppins(
                            fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ]),
              Text(user.phone.isNotEmpty ? user.phone : 'Sem telefone',
                  style: GoogleFonts.poppins(fontSize: 12, color: FC.textLight)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Pill(label: '${user.petCount} pet${user.petCount != 1 ? "s" : ""}', color: FC.catShop),
            const SizedBox(height: 4),
            _Pill(label: '${user.favoriteCount} fav${user.favoriteCount != 1 ? "s" : ""}', color: FC.secondary),
          ],
        ),
      ]),
    );
  }
}

// ── Pets ──────────────────────────────────────────────────────────────────────

class _PetsTab extends StatefulWidget {
  const _PetsTab();

  @override
  State<_PetsTab> createState() => _PetsTabState();
}

class _PetsTabState extends State<_PetsTab> {
  List<AdminPet> _all = [];
  List<AdminPet> _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final pets = await AdminService().getPets();
    if (!mounted) return;
    setState(() { _all = pets; _loading = false; _filter(); });
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.ownerName.toLowerCase().contains(q) ||
              p.breed.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: _PageHeader(title: 'Pets (${_all.length})', onRefresh: _load),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _SearchField(controller: _search, hint: 'Buscar por nome, raça ou tutor'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: FC.blue))
              : _filtered.isEmpty
                  ? const _EmptyState(label: 'Nenhum pet encontrado')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _PetRow(pet: _filtered[i]),
                    ),
        ),
      ],
    );
  }
}

class _PetRow extends StatelessWidget {
  final AdminPet pet;
  const _PetRow({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FR.card),
        boxShadow: FS.card,
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: const BoxDecoration(color: FC.blueLight, shape: BoxShape.circle),
          child: Center(child: Text(pet.speciesEmoji, style: const TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pet.name,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700, color: FC.textDark)),
              Text('${pet.breed} · ${pet.ageLabel}',
                  style: GoogleFonts.poppins(fontSize: 12, color: FC.textMid)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Pill(label: pet.species, color: FC.blue),
            const SizedBox(height: 4),
            Text(pet.ownerName,
                style: GoogleFonts.poppins(fontSize: 11, color: FC.textLight)),
          ],
        ),
      ]),
    );
  }
}

// ── Favorites ─────────────────────────────────────────────────────────────────

class _FavoritesTab extends StatefulWidget {
  const _FavoritesTab();

  @override
  State<_FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<_FavoritesTab> {
  List<AdminFavorite> _all = [];
  List<AdminFavorite> _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final favs = await AdminService().getFavorites();
    if (!mounted) return;
    setState(() { _all = favs; _loading = false; _filter(); });
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((f) =>
              f.serviceName.toLowerCase().contains(q) ||
              f.userName.toLowerCase().contains(q) ||
              f.serviceCategory.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: _PageHeader(title: 'Favoritos (${_all.length})', onRefresh: _load),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _SearchField(controller: _search, hint: 'Buscar por serviço, usuário ou categoria'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: FC.blue))
              : _filtered.isEmpty
                  ? const _EmptyState(label: 'Nenhum favorito encontrado')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _FavoriteRow(fav: _filtered[i]),
                    ),
        ),
      ],
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  final AdminFavorite fav;
  const _FavoriteRow({required this.fav});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FR.card),
        boxShadow: FS.card,
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: FC.secondary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite_rounded, color: FC.secondary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fav.serviceName,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700, color: FC.textDark),
                  overflow: TextOverflow.ellipsis),
              Text(fav.serviceAddress,
                  style: GoogleFonts.poppins(fontSize: 11, color: FC.textLight),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Pill(label: fav.serviceCategory, color: FC.catVet),
            const SizedBox(height: 4),
            Text(fav.userName,
                style: GoogleFonts.poppins(fontSize: 11, color: FC.textLight)),
          ],
        ),
      ]),
    );
  }
}

// ── Estabelecimentos ──────────────────────────────────────────────────────────

class _EstabelecimentosTab extends StatefulWidget {
  const _EstabelecimentosTab();

  @override
  State<_EstabelecimentosTab> createState() => _EstabelecimentosTabState();
}

class _EstabelecimentosTabState extends State<_EstabelecimentosTab> {
  List<ServiceModel> _all = [];
  List<ServiceModel> _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await EstablishmentsService().fetchAll();
    if (!mounted) return;
    setState(() { _all = items; _loading = false; _filter(); });
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.category.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _openForm([ServiceModel? service]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EstablishmentFormScreen(service: service),
      ),
    );
    if (!mounted) return;
    if (result == true) _load();
  }

  Future<void> _delete(ServiceModel s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Excluir estabelecimento?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(s.name, style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: FC.textLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir', style: GoogleFonts.poppins(
                color: FC.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (!mounted || confirm != true) return;
    await EstablishmentsService().delete(s.id);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estabelecimentos (${_all.length})',
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w800, color: FC.textDark)),
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: FC.blue),
                  tooltip: 'Atualizar',
                  onPressed: _load,
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('Novo', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FC.blue,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ]),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _SearchField(controller: _search, hint: 'Buscar por nome, categoria ou endereço'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: FC.blue))
              : _filtered.isEmpty
                  ? const _EmptyState(label: 'Nenhum estabelecimento cadastrado')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _EstabelecimentoRow(
                        service: _filtered[i],
                        onEdit: () => _openForm(_filtered[i]),
                        onDelete: () => _delete(_filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _EstabelecimentoRow extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EstabelecimentoRow({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _catColor {
    switch (service.category) {
      case Cat.vet:     return FC.catVet;
      case Cat.shop:    return FC.catShop;
      case Cat.banho:   return FC.catBanho;
      case Cat.hotel:   return FC.catHotel;
      case Cat.passeio: return FC.catPasseio;
      case Cat.adest:   return FC.catAdest;
      default:          return FC.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FR.card),
        boxShadow: FS.card,
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: _catColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.storefront_rounded, color: _catColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(service.name,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700, color: FC.textDark),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                _Pill(label: service.category, color: _catColor),
                const SizedBox(width: 6),
                _Pill(
                  label: service.isOpen ? 'Aberto' : 'Fechado',
                  color: service.isOpen ? FC.success : FC.error,
                ),
                const SizedBox(width: 6),
                if (service.rating > 0)
                  Row(children: [
                    const Icon(Icons.star_rounded, color: FC.warning, size: 12),
                    Text(' ${service.rating.toStringAsFixed(1)}',
                        style: GoogleFonts.poppins(fontSize: 11, color: FC.textMid)),
                  ]),
              ]),
              if (service.address.isNotEmpty)
                Text(service.address,
                    style: GoogleFonts.poppins(fontSize: 11, color: FC.textLight),
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: FC.blue, size: 20),
          tooltip: 'Editar',
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: FC.error, size: 20),
          tooltip: 'Excluir',
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback onRefresh;
  const _PageHeader({required this.title, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.w800, color: FC.textDark)),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: FC.blue),
          tooltip: 'Atualizar',
          onPressed: onRefresh,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w700, color: FC.textDark));
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _SearchField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(fontSize: 14, color: FC.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: FC.textLight),
        prefixIcon: const Icon(Icons.search_rounded, color: FC.textLight, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FR.pill),
          borderSide: const BorderSide(color: FC.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FR.pill),
          borderSide: const BorderSide(color: FC.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FR.pill),
          borderSide: const BorderSide(color: FC.blue, width: 2),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: FC.textLight),
          const SizedBox(height: 12),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 14, color: FC.textLight)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
