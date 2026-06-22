import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/establishments_service.dart';
import '../../theme/app_theme.dart';

class EstablishmentFormScreen extends StatefulWidget {
  final ServiceModel? service; // null = criar novo

  const EstablishmentFormScreen({super.key, this.service});

  @override
  State<EstablishmentFormScreen> createState() => _EstablishmentFormScreenState();
}

class _EstablishmentFormScreenState extends State<EstablishmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _description;
  late final TextEditingController _rating;
  late final TextEditingController _reviewCount;

  late String _category;
  late bool _isOpen;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _name        = TextEditingController(text: s?.name ?? '');
    _address     = TextEditingController(text: s?.address ?? '');
    _lat         = TextEditingController(text: s != null ? '${s.lat}' : '');
    _lng         = TextEditingController(text: s != null ? '${s.lng}' : '');
    _phone       = TextEditingController(text: s?.phone ?? '');
    _whatsapp    = TextEditingController(text: s?.whatsapp ?? '');
    _description = TextEditingController(text: s?.description ?? '');
    _rating      = TextEditingController(text: s != null ? '${s.rating}' : '0');
    _reviewCount = TextEditingController(text: s != null ? '${s.reviewCount}' : '0');
    _category    = s?.category ?? Cat.all.first;
    _isOpen      = s?.isOpen ?? true;
  }

  @override
  void dispose() {
    for (final c in [_name, _address, _lat, _lng, _phone, _whatsapp, _description, _rating, _reviewCount]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    final data = {
      'name':         _name.text.trim(),
      'category':     _category,
      'address':      _address.text.trim(),
      'lat':          double.tryParse(_lat.text) ?? 0,
      'lng':          double.tryParse(_lng.text) ?? 0,
      'phone':        _phone.text.trim(),
      'whatsapp':     _whatsapp.text.trim(),
      'description':  _description.text.trim(),
      'rating':       double.tryParse(_rating.text) ?? 0,
      'review_count': int.tryParse(_reviewCount.text) ?? 0,
      'is_open':      _isOpen,
      'photo_urls':   <String>[],
      'hours':        <String, String>{},
    };

    bool ok;
    if (_isEditing) {
      ok = await EstablishmentsService().update(widget.service!.id, data);
    } else {
      final created = await EstablishmentsService().create(data);
      ok = created != null;
    }

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = 'Erro ao salvar. Verifique se você tem permissão de admin.';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FC.bg,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Estabelecimento' : 'Novo Estabelecimento'),
        actions: [
          if (_saving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: FC.blue),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text('Salvar',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, color: FC.blue, fontSize: 15)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FC.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(FR.sm),
                  border: Border.all(color: FC.error.withValues(alpha: 0.4)),
                ),
                child: Text(_error!,
                    style: GoogleFonts.poppins(fontSize: 13, color: FC.error)),
              ),

            const _SectionLabel(text: 'Informações básicas'),
            const SizedBox(height: 12),

            _Field(
              controller: _name,
              label: 'Nome do estabelecimento',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),

            // Categoria dropdown
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _inputDeco('Categoria'),
              items: Cat.all.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
              style: GoogleFonts.poppins(fontSize: 14, color: FC.textDark),
            ),
            const SizedBox(height: 12),

            _Field(
              controller: _address,
              label: 'Endereço completo',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 24),

            const _SectionLabel(text: 'Coordenadas GPS'),
            const SizedBox(height: 4),
            Text(
              'Acesse maps.google.com, clique com botão direito no local e copie as coordenadas.',
              style: GoogleFonts.poppins(fontSize: 12, color: FC.textLight),
            ),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                child: _Field(
                  controller: _lat,
                  label: 'Latitude',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obrigatório';
                    if (double.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  controller: _lng,
                  label: 'Longitude',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obrigatório';
                    if (double.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
              ),
            ]),
            const SizedBox(height: 24),

            const _SectionLabel(text: 'Contato'),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                child: _Field(
                  controller: _phone,
                  label: 'Telefone',
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  controller: _whatsapp,
                  label: 'WhatsApp (só números)',
                  keyboardType: TextInputType.phone,
                ),
              ),
            ]),
            const SizedBox(height: 24),

            const _SectionLabel(text: 'Detalhes'),
            const SizedBox(height: 12),

            _Field(
              controller: _description,
              label: 'Descrição',
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                child: _Field(
                  controller: _rating,
                  label: 'Avaliação (0–5)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  controller: _reviewCount,
                  label: 'Nº de avaliações',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Is Open toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(FR.sm),
                border: Border.all(color: FC.divider),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status atual',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600, color: FC.textDark)),
                      Text(_isOpen ? 'Aberto' : 'Fechado',
                          style: GoogleFonts.poppins(fontSize: 12, color: _isOpen ? FC.success : FC.error)),
                    ],
                  ),
                ),
                Switch(
                  value: _isOpen,
                  onChanged: (v) => setState(() => _isOpen = v),
                  activeThumbColor: FC.success,
                ),
              ]),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FR.sm),
          borderSide: const BorderSide(color: FC.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FR.sm),
          borderSide: const BorderSide(color: FC.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FR.sm),
          borderSide: const BorderSide(color: FC.blue, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: FC.textLight),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14, color: FC.textDark),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FR.sm),
          borderSide: const BorderSide(color: FC.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FR.sm),
          borderSide: const BorderSide(color: FC.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FR.sm),
          borderSide: const BorderSide(color: FC.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FR.sm),
          borderSide: const BorderSide(color: FC.error),
        ),
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: FC.textLight),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w700, color: FC.textMid,
            letterSpacing: 0.4));
  }
}
