import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/vaccine_service.dart';

class VaccineCardScreen extends StatefulWidget {
  final Map<String, dynamic> pet;
  const VaccineCardScreen({super.key, required this.pet});

  @override
  State<VaccineCardScreen> createState() => _VaccineCardState();
}

class _VaccineCardState extends State<VaccineCardScreen> {
  List<Map<String, dynamic>> _vaccines = [];
  bool _loading = true;

  String get _emoji {
    final s = widget.pet['species'] ?? '';
    if (s == 'Cachorro') return '🐶';
    if (s == 'Gato') return '🐱';
    return '🐾';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await VaccineService().getVaccines(widget.pet['id']);
    if (mounted) setState(() { _vaccines = list; _loading = false; });
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddVaccineSheet(
        petId: widget.pet['id'],
        onSaved: () { Navigator.pop(context); _load(); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FC.bg,
      body: Column(children: [
        // ── Header ───────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: FC.blue,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: FC.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Text('Cartão de Vacinas',
                      style: GoogleFonts.poppins(
                          color: FC.white, fontWeight: FontWeight.w700, fontSize: 18)),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                        color: FC.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle),
                    child: Center(
                        child: Text(_emoji,
                            style: const TextStyle(fontSize: 28))),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.pet['name'] ?? '',
                        style: GoogleFonts.poppins(
                            color: FC.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
                    Text(
                      '${widget.pet['breed'] ?? ''} · ${widget.pet['species'] ?? ''}',
                      style: GoogleFonts.poppins(
                          color: FC.white.withValues(alpha: 0.75), fontSize: 13),
                    ),
                  ]),
                  const Spacer(),
                  // Contador de vacinas
                  if (!_loading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: FC.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(50)),
                      child: Text(
                        '${_vaccines.length} ${_vaccines.length == 1 ? "vacina" : "vacinas"}',
                        style: GoogleFonts.poppins(
                            color: FC.white, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                ]),
              ]),
            ),
          ),
        ),

        // ── Lista ────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: FC.blue))
              : _vaccines.isEmpty
                  ? _EmptyVaccines(onAdd: _showAddSheet)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 100),
                      itemCount: _vaccines.length,
                      itemBuilder: (_, i) {
                        final v = _vaccines[i];
                        return _VaccineCard(
                          vaccine: v,
                          onDelete: () async {
                            final ok = await VaccineService().deleteVaccine(v['id']);
                            if (ok && mounted) {
                              setState(() => _vaccines
                                  .removeWhere((x) => x['id'] == v['id']));
                            }
                          },
                        );
                      },
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: FC.blue,
        icon: const Icon(Icons.add_rounded, color: FC.white),
        label: Text('Adicionar vacina',
            style: GoogleFonts.poppins(
                color: FC.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Card de vacina
// ─────────────────────────────────────────
class _VaccineCard extends StatelessWidget {
  final Map<String, dynamic> vaccine;
  final VoidCallback onDelete;

  const _VaccineCard({required this.vaccine, required this.onDelete});

  String _fmt(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FC.white,
        borderRadius: BorderRadius.circular(FR.card),
        boxShadow: FS.card,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              color: FC.blueLight, borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.vaccines_rounded, color: FC.blue, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(vaccine['name'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: FC.textDark)),
              ),
              const SizedBox(width: 8),
              _StatusChip(nextAt: vaccine['next_at'] as String?),
            ]),
            const SizedBox(height: 6),
            _InfoRow(Icons.calendar_today_rounded,
                'Aplicada: ${_fmt(vaccine['applied_at'] as String?)}'),
            if (vaccine['next_at'] != null)
              _InfoRow(Icons.event_rounded,
                  'Próxima dose: ${_fmt(vaccine['next_at'] as String?)}'),
            if ((vaccine['vet'] as String?)?.isNotEmpty == true)
              _InfoRow(Icons.person_rounded, vaccine['vet'] as String),
            if ((vaccine['notes'] as String?)?.isNotEmpty == true)
              _InfoRow(Icons.notes_rounded, vaccine['notes'] as String),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: FC.error, size: 20),
          onPressed: () => _confirmDelete(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remover vacina?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Remover "${vaccine['name']}" do cartão?',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: FC.textMid)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); onDelete(); },
            style: ElevatedButton.styleFrom(
                backgroundColor: FC.error, minimumSize: const Size(0, 40)),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          Icon(icon, size: 12, color: FC.textLight),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(fontSize: 12, color: FC.textMid),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );
}

// ─────────────────────────────────────────
// Chip de status (vencida / em breve / ok)
// ─────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String? nextAt;
  const _StatusChip({this.nextAt});

  @override
  Widget build(BuildContext context) {
    if (nextAt == null) return _chip('Dose única', FC.textLight);
    final next = DateTime.tryParse(nextAt!);
    if (next == null) return _chip('Dose única', FC.textLight);
    final diff = next.difference(DateTime.now()).inDays;
    if (diff < 0) return _chip('Vencida', FC.error);
    if (diff <= 30) return _chip('Vence em breve', FC.warning);
    return _chip('Em dia', FC.success);
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(50)),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}

// ─────────────────────────────────────────
// Estado vazio
// ─────────────────────────────────────────
class _EmptyVaccines extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyVaccines({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(color: FC.blueLight, shape: BoxShape.circle),
          child: const Icon(Icons.vaccines_rounded, color: FC.blue, size: 42),
        ),
        const SizedBox(height: 20),
        Text('Nenhuma vacina registrada',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700, color: FC.textDark)),
        const SizedBox(height: 8),
        Text('Mantenha o cartão de vacinas\ndo seu pet sempre atualizado',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 13, color: FC.textMid, height: 1.5)),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Adicionar vacina'),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// Bottom sheet — adicionar vacina
// ─────────────────────────────────────────
class _AddVaccineSheet extends StatefulWidget {
  final String petId;
  final VoidCallback onSaved;
  const _AddVaccineSheet({required this.petId, required this.onSaved});

  @override
  State<_AddVaccineSheet> createState() => _AddVaccineSheetState();
}

class _AddVaccineSheetState extends State<_AddVaccineSheet> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _vetCtrl = TextEditingController();
  DateTime _appliedAt = DateTime.now();
  DateTime? _nextAt;
  bool _loading = false;

  static const _commonVaccines = [
    'V8', 'V10', 'Antirrábica', 'Gripe Canina',
    'Leishmaniose', 'V4 Felina', 'Raiva Felina', 'FeLV',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isNext) async {
    final initial = isNext
        ? (_nextAt ?? DateTime.now().add(const Duration(days: 365)))
        : _appliedAt;
    final first = isNext ? DateTime.now() : DateTime(2000);
    final last = DateTime.now().add(const Duration(days: 365 * 5));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() {
        if (isNext) {
          _nextAt = picked;
        } else {
          _appliedAt = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await VaccineService().addVaccine(
      petId: widget.petId,
      name: _nameCtrl.text.trim(),
      appliedAt: _appliedAt,
      nextAt: _nextAt,
      vet: _vetCtrl.text.trim().isEmpty ? null : _vetCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao salvar vacina.',
            style: GoogleFonts.poppins(color: FC.white)),
        backgroundColor: FC.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: FC.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(22, 16, 22, 24 + bottom),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: FC.divider,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('Nova Vacina',
              style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: FC.textDark)),
          const SizedBox(height: 14),

          // Chips de vacinas comuns
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonVaccines.map((v) {
              final sel = _nameCtrl.text == v;
              return GestureDetector(
                onTap: () => setState(() => _nameCtrl.text = v),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? FC.blue : FC.blueLight,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(v,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sel ? FC.white : FC.blue)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Nome da vacina
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(hintText: 'Nome da vacina'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Informe o nome da vacina' : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Datas
          Row(children: [
            Expanded(
              child: _DateTile(
                label: 'Aplicada em',
                date: _appliedAt,
                onTap: () => _pickDate(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateTile(
                label: 'Próxima dose',
                date: _nextAt,
                onTap: () => _pickDate(true),
                optional: true,
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Veterinário
          TextFormField(
            controller: _vetCtrl,
            decoration: const InputDecoration(hintText: 'Veterinário (opcional)'),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: FC.white, strokeWidth: 2))
                : const Text('Salvar'),
          ),
        ]),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool optional;

  const _DateTile({
    required this.label,
    this.date,
    required this.onTap,
    this.optional = false,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: FC.blueLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FC.blue.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600, color: FC.blue)),
          const SizedBox(height: 3),
          Text(
            date != null ? _fmt(date!) : (optional ? 'Não definido' : 'Selecionar'),
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: date != null ? FC.textDark : FC.textLight),
          ),
        ]),
      ),
    );
  }
}
