import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../services/auth_service.dart';
import '../services/supabase_config.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ProfileEditScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEditScreen> {
  final _form = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  late final TextEditingController _newPassCtrl;
  late final TextEditingController _confirmPassCtrl;

  File? _photoFile;

  String? _existingPhotoUrl;

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController(
      text: widget.profile['name'] ?? '',
    );

    _phoneCtrl = TextEditingController(
      text: widget.profile['phone'] ?? '',
    );

    _emailCtrl = TextEditingController(
      text: AuthService().currentUser?.email ?? '',
    );

    _newPassCtrl = TextEditingController();

    _confirmPassCtrl = TextEditingController();

    _existingPhotoUrl = widget.profile['photo_url'];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────
  // ESCOLHER FOTO
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
      maxWidth: 900,
      maxHeight: 900,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _photoFile = File(picked.path);
      });
    }
  }

  // ─────────────────────────────────────────
  // UPLOAD FOTO
  // ─────────────────────────────────────────

  Future<String?> _uploadPhoto() async {
    if (_photoFile == null) {
      return _existingPhotoUrl;
    }

    try {
      final db = Supabase.instance.client;

      final uid = db.auth.currentUser?.id;

      if (uid == null) {
        return _existingPhotoUrl;
      }

      final ext = _photoFile!.path.split('.').last.toLowerCase();

      final fileName = '$uid/profile_${const Uuid().v4()}.$ext';

      await db.storage.from(SupabaseConfig.profilePhotosBucket).upload(
            fileName,
            _photoFile!,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );

      final publicUrl = db.storage
          .from(SupabaseConfig.profilePhotosBucket)
          .getPublicUrl(fileName);

      // força atualização da imagem
      return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('upload photo error = $e');

      return _existingPhotoUrl;
    }
  }

  // ─────────────────────────────────────────
  // SALVAR
  // ─────────────────────────────────────────

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    final photoUrl = await _uploadPhoto();

    final res = await AuthService().updateProfile(
      name: _nameCtrl.text,
      phone: _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : null,
      photoUrl: photoUrl,
    );

    if (!mounted) return;

    // ALTERAR SENHA
    if (res.success && _newPassCtrl.text.isNotEmpty) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            password: _newPassCtrl.text,
          ),
        );
      } catch (e) {
        setState(() {
          _loading = false;
        });

        _snack(
          'Perfil salvo, mas erro ao alterar senha.',
          FC.error,
        );

        return;
      }
    }

    setState(() {
      _loading = false;
    });

    if (!mounted) return;

    if (res.success) {
      Navigator.pop(context, true);
    } else {
      _snack(
        res.error ?? 'Erro ao atualizar perfil.',
        FC.error,
      );
    }
  }

  // ─────────────────────────────────────────
  // SNACKBAR
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
  // AVATAR
  // ─────────────────────────────────────────

  Widget _photoAvatar() {
    Widget inner;

    if (_photoFile != null) {
      inner = ClipOval(
        child: Image.file(
          _photoFile!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    } else if (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty) {
      inner = ClipOval(
        child: CachedNetworkImage(
          key: ValueKey(_existingPhotoUrl),
          imageUrl:
              '$_existingPhotoUrl?v=${DateTime.now().millisecondsSinceEpoch}',
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          memCacheWidth: 400,
          maxWidthDiskCache: 400,
          fadeInDuration: Duration.zero,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(
              color: FC.blue,
              strokeWidth: 2,
            ),
          ),
          errorWidget: (_, __, ___) => const Icon(
            Icons.person,
            color: FC.blue,
            size: 40,
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
            child: Center(child: inner),
          ),
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
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────

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
          title: Text(
            'Editar Perfil',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: FC.white,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER

              Container(
                color: FC.blue,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  32,
                ),
                child: Center(
                  child: _photoAvatar(),
                ),
              ),

              // FORM

              Padding(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NOME

                      PillField(
                        hint: 'Nome completo',
                        controller: _nameCtrl,
                        validator: (v) {
                          if (v == null || v.trim().length < 3) {
                            return 'Nome muito curto';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // EMAIL

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: FC.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: FC.divider,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: FC.textMid,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _emailCtrl.text,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: FC.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Email não pode ser alterado',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: FC.textLight,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // TELEFONE

                      PillField(
                        hint: 'Telefone (opcional)',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 28),

                      // SENHA

                      const Divider(
                        color: FC.divider,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Alterar senha',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: FC.textDark,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Deixe em branco para manter a senha atual.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: FC.textLight,
                        ),
                      ),

                      const SizedBox(height: 12),

                      PillField(
                        hint: 'Nova senha (mín. 6 caracteres)',
                        controller: _newPassCtrl,
                        obscure: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return null;
                          }

                          if (v.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      PillField(
                        hint: 'Confirmar nova senha',
                        controller: _confirmPassCtrl,
                        obscure: true,
                        validator: (v) {
                          if (_newPassCtrl.text.isEmpty) {
                            return null;
                          }

                          if (v != _newPassCtrl.text) {
                            return 'Senhas não conferem';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // BOTÃO

                      PillButton(
                        label: _loading ? 'Salvando...' : 'Salvar alterações',
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
