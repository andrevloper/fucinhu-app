import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../services/pet_service.dart';
import 'main_screen.dart';

class PetFormScreen extends StatefulWidget {
  final Map<String, dynamic>? pet;
  final String? userName;

  const PetFormScreen({
    super.key,
    this.pet,
    this.userName,
  });

  @override
  State<PetFormScreen> createState() => _PetFormState();
}

class _PetFormState extends State<PetFormScreen> {
  final _form = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _species = 'Cachorro';
  int _ageMonths = 12;

  File? _photoFile;
  String? _existingPhotoUrl;

  bool _loading = false;
  bool _isFirstSignUp = false;

  static const _speciesList = [
    'Cachorro',
    'Gato',
    'Pássaro',
    'Coelho',
    'Outro',
  ];

  bool get _isEditing => widget.pet != null;

  @override
  void initState() {
    super.initState();

    _isFirstSignUp = widget.userName != null && !_isEditing;

    if (_isEditing) {
      final p = widget.pet!;

      _nameCtrl.text = p['name'] ?? '';
      _breedCtrl.text = p['breed'] ?? '';
      _notesCtrl.text = p['notes'] ?? '';

      _species = p['species'] ?? 'Cachorro';
      _ageMonths = p['age_months'] ?? 12;

      _existingPhotoUrl = p['photo_url'];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // Selecionar foto
  // ─────────────────────────────────────────

  Future<void> _pickPhoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FC.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: FC.blue,
              ),
              title: Text(
                'Tirar foto',
                style: GoogleFonts.poppins(),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: FC.blue,
              ),
              title: Text(
                'Escolher da galeria',
                style: GoogleFonts.poppins(),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pick(ImageSource.gallery);
              },
            ),
            if (_existingPhotoUrl != null || _photoFile != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: FC.error,
                ),
                title: Text(
                  'Remover foto',
                  style: GoogleFonts.poppins(
                    color: FC.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);

                  setState(() {
                    _photoFile = null;
                    _existingPhotoUrl = null;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _photoFile = File(picked.path);
      });
    }
  }

  // ─────────────────────────────────────────
  // Salvar
  // ─────────────────────────────────────────

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);

    if (_isEditing) {
      final res = await PetService().updatePet(
        petId: widget.pet!['id'],
        name: _nameCtrl.text,
        species: _species,
        breed: _breedCtrl.text,
        ageMonths: _ageMonths,
        notes: _notesCtrl.text,
        photoFile: _photoFile,
        existingPhotoUrl: _existingPhotoUrl,
      );

      if (!mounted) return;

      setState(() => _loading = false);

      if (res.success) {
        Navigator.pop(context, true);
      } else {
        _snack(res.error ?? 'Erro ao atualizar.', FC.error);
      }
    } else {
      final res = await PetService().createPet(
        name: _nameCtrl.text,
        species: _species,
        breed: _breedCtrl.text,
        ageMonths: _ageMonths,
        notes: _notesCtrl.text,
        photoFile: _photoFile,
      );

      if (!mounted) return;

      setState(() => _loading = false);

      if (res.success) {
        // Atualiza URL da imagem imediatamente
        if (res.pet != null) {
          _existingPhotoUrl = res.pet!['photo_url'];
        }

        if (_isFirstSignUp) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => MainScreen(
                userName: widget.userName ?? 'Tutor',
              ),
            ),
            (_) => false,
          );
        } else {
          final outro = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Pet cadastrado! 🐾',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                'Deseja cadastrar outro pet?',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Não, obrigado',
                    style: GoogleFonts.poppins(
                      color: FC.textMid,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('Sim, cadastrar'),
                ),
              ],
            ),
          );

          if (!mounted) return;

          if (outro == true) {
            _nameCtrl.clear();
            _breedCtrl.clear();
            _notesCtrl.clear();

            setState(() {
              _photoFile = null;
              _existingPhotoUrl = null;
              _species = 'Cachorro';
              _ageMonths = 12;
            });
          } else {
            Navigator.pop(context, true);
          }
        }
      } else {
        _snack(res.error ?? 'Erro ao salvar.', FC.error);
      }
    }
  }

  // ─────────────────────────────────────────
  // Snackbar
  // ─────────────────────────────────────────

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(
            color: FC.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Avatar
  // ─────────────────────────────────────────

  Widget _photoAvatar() {
    final hasPhoto = _photoFile != null ||
        (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty);

    Widget inner;

    // Foto local
    if (_photoFile != null) {
      inner = ClipOval(
        child: Image.file(
          _photoFile!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );

      // Foto Supabase
    } else if (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty) {
      inner = ClipOval(
        child: CachedNetworkImage(
          imageUrl: _existingPhotoUrl!,
          width: 100,
          height: 100,
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
          errorWidget: (_, __, ___) => Container(
            color: FC.blueLight,
            child: const Icon(
              Icons.pets,
              color: FC.blue,
              size: 40,
            ),
          ),
        ),
      );
    } else {
      inner = const Icon(
        Icons.add_a_photo_rounded,
        color: FC.blue,
        size: 34,
      );
    }

    return GestureDetector(
      onTap: _pickPhoto,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: FC.blueLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: FC.blue,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Center(
                child: inner,
              ),
            ),
          ),

          // Editar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: FC.blue,
              shape: BoxShape.circle,
              border: Border.all(
                color: FC.white,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.edit,
              color: FC.white,
              size: 14,
            ),
          ),

          // Indicador de foto
          if (hasPhoto)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FC.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      loading: _loading,
      child: Scaffold(
        backgroundColor: FC.bg,
        appBar: AppBar(
          backgroundColor: FC.blue,
          foregroundColor: FC.white,
          elevation: 0,
          title: Image.asset(
            'assets/images/logo.png',
            height: 38,
            color: FC.white,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (_, __, ___) => Text(
              'Fucinho.co',
              style: GoogleFonts.poppins(
                color: FC.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          actions: _isFirstSignUp
              ? [
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MainScreen(
                            userName: widget.userName ?? 'Tutor',
                          ),
                        ),
                        (_) => false,
                      );
                    },
                    child: Text(
                      'Pular',
                      style: GoogleFonts.poppins(
                        color: FC.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]
              : null,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header azul
              Container(
                color: FC.blue,
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        _isEditing ? 0 : 16,
                        24,
                        _isEditing ? 20 : 12,
                      ),
                      child: Text(
                        _isEditing ? 'Editar pet' : 'Cadastrar pet',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: FC.white,
                        ),
                      ),
                    ),
                    if (!_isEditing)
                      Image.asset(
                        'assets/images/pet_hug.png',
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.bottomCenter,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: _photoAvatar(),
                      ),

                      const SizedBox(height: 6),

                      Center(
                        child: Text(
                          _photoFile != null ||
                                  (_existingPhotoUrl != null &&
                                      _existingPhotoUrl!.isNotEmpty)
                              ? 'Toque para alterar'
                              : 'Adicionar foto',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: FC.textMid,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Nome
                      PillField(
                        hint: 'Nome do pet',
                        controller: _nameCtrl,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Obrigatório';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Espécie
                      Text(
                        'Espécie',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: FC.textMid,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _speciesList.map((sp) {
                          final sel = _species == sp;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _species = sp;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: sel ? FC.blue : FC.surfaceAlt,
                                borderRadius: BorderRadius.circular(
                                  FR.pill,
                                ),
                                border: Border.all(
                                  color: sel ? FC.blue : FC.divider,
                                ),
                              ),
                              child: Text(
                                sp,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: sel ? FC.white : FC.textDark,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Raça
                      PillField(
                        hint: 'Raça (ex: Labrador, SRD...)',
                        controller: _breedCtrl,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Obrigatório';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Idade
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Idade',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: FC.textMid,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: FC.blueLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _ageMonths < 12
                                  ? '$_ageMonths meses'
                                  : '${_ageMonths ~/ 12} ${_ageMonths ~/ 12 == 1 ? "ano" : "anos"}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: FC.blue,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: FC.blue,
                          inactiveTrackColor: FC.divider,
                          thumbColor: FC.blue,
                          overlayColor: FC.blue.withValues(alpha: 0.15),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: _ageMonths.toDouble(),
                          min: 1,
                          max: 240,
                          onChanged: (v) {
                            setState(() {
                              _ageMonths = v.round();
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Observações
                      PillField(
                        hint: 'Observações (alergias, medicamentos...)',
                        controller: _notesCtrl,
                      ),

                      const SizedBox(height: 32),

                      PillButton(
                        label: _loading
                            ? 'Salvando...'
                            : (_isEditing
                                ? 'Salvar alterações'
                                : 'Cadastrar pet'),
                        onTap: _loading ? () {} : _save,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
