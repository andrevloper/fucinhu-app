import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../services/pet_service.dart';
import 'pet_form_screen.dart';
import 'vaccine_card_screen.dart';

class PetsListScreen extends StatefulWidget {
  const PetsListScreen({super.key});

  @override
  State<PetsListScreen> createState() => _PetsListState();
}

class _PetsListState extends State<PetsListScreen> {
  List<Map<String, dynamic>> _pets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final pets = await PetService().getPets();
      if (!mounted) return;
      setState(() {
        _pets = pets;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _deletePet(Map<String, dynamic> pet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(FR.xl)),
        title: Text(
          'Remover ${pet['name']}?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Esta ação não pode ser desfeita.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: FC.textMid),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FC.error,
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await PetService().deletePet(pet['id']);

      if (ok && mounted) {
        setState(() {
          _pets.removeWhere((p) => p['id'] == pet['id']);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${pet['name']} removido.',
              style: GoogleFonts.poppins(color: FC.white),
            ),
            backgroundColor: FC.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _avatar(Map<String, dynamic> pet) {
    final photo = pet['photo_url']?.toString();

    final emoji = pet['species'] == 'Cachorro'
        ? '🐶'
        : pet['species'] == 'Gato'
            ? '🐱'
            : '🐾';

    if (photo != null && photo.isNotEmpty && photo.startsWith('http')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photo,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          placeholder: (_, __) => const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: FC.blue,
              ),
            ),
          ),
          errorWidget: (_, __, ___) {
            return Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
            );
          },
        ),
      );
    }

    return Center(
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 32),
      ),
    );
  }

  String _ageLabel(int months) {
    if (months < 12) {
      return '$months ${months == 1 ? "mês" : "meses"}';
    }

    final years = months ~/ 12;

    return '$years ${years == 1 ? "ano" : "anos"}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FC.bg,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: FC.blue,
        foregroundColor: FC.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Adicionar',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const PetFormScreen(),
            ),
          );

          if (added == true) {
            _load();
          }
        },
      ),
      body: RefreshIndicator(
        color: FC.blue,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // HEADER
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
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Pets',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: FC.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _loading
                              ? 'Carregando...'
                              : _pets.isEmpty
                                  ? 'Nenhum pet cadastrado'
                                  : '${_pets.length} ${_pets.length == 1 ? "pet cadastrado" : "pets cadastrados"}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: FC.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // LOADING
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: FC.blue,
                    ),
                  ),
                ),
              )

            // ERROR
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: FC.textLight, size: 64),
                      const SizedBox(height: 18),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 14, color: FC.textMid, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text('Tentar novamente', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              )

            // EMPTY
            else if (_pets.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 70,
                    horizontal: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pets_rounded,
                        color: FC.blueLight,
                        size: 70,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Nenhum pet cadastrado',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: FC.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Adicione seu primeiro pet tocando no botão abaixo.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: FC.textMid,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )

            // LISTA
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final pet = _pets[i];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: FC.white,
                          borderRadius: BorderRadius.circular(FR.card),
                          boxShadow: [
                            BoxShadow(
                              color: FC.blue.withValues(alpha: 0.07),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // FOTO
                            Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: FC.blueLight,
                                shape: BoxShape.circle,
                              ),
                              child: _avatar(pet),
                            ),

                            const SizedBox(width: 16),

                            // DADOS
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pet['name'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: FC.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${pet['breed']} · ${_ageLabel(pet['age_months'] ?? 0)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: FC.textMid,
                                    ),
                                  ),
                                  if ((pet['notes'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        pet['notes'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: FC.textLight,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // AÇÕES
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.vaccines_rounded,
                                    color: FC.catVet,
                                    size: 24,
                                  ),
                                  tooltip: 'Carteira de vacinação',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VaccineCardScreen(
                                          pet: pet,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: FC.blue,
                                    size: 23,
                                  ),
                                  onPressed: () async {
                                    final updated = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PetFormScreen(
                                          pet: pet,
                                        ),
                                      ),
                                    );

                                    if (updated == true) {
                                      _load();
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: FC.error,
                                    size: 23,
                                  ),
                                  onPressed: () => _deletePet(pet),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: _pets.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
