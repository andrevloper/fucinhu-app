import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'main_screen.dart';

class PetChoiceScreen extends StatefulWidget {
  final String userName;

  const PetChoiceScreen({
    super.key,
    this.userName = 'Tutor',
  });

  @override
  State<PetChoiceScreen> createState() => _PetChoiceState();
}

class _PetChoiceState extends State<PetChoiceScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();

  String? _species;

  late final AnimationController _arrowCtrl;
  late final Animation<double> _arrowScale;

  @override
  void initState() {
    super.initState();

    _arrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _arrowScale = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(
      CurvedAnimation(
        parent: _arrowCtrl,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _arrowCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _selectSpecies(String species) {
    setState(() => _species = species);

    if (!_arrowCtrl.isAnimating) {
      _arrowCtrl.repeat(reverse: true);
    }
  }

  void _next() {
    if (_species == null) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MainScreen(
          userName: widget.userName,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _species != null;

    final mq = MediaQuery.of(context);

    final screenHeight = mq.size.height - mq.padding.top - mq.padding.bottom;

    return Scaffold(
      backgroundColor: FC.white,
      body: Column(
        children: [
          // HEADER AZUL
          Container(
            height: screenHeight * 0.56,
            decoration: const BoxDecoration(
              color: FC.blue,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(34),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // VOLTAR
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: FC.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: FC.white,
                          size: 22,
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // TÍTULO
                    Text(
                      'A escolha do\nseu Fucinhu pet',
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: FC.white,
                        height: 1.15,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Escolha o tipo do seu pet para\npersonalizar sua experiência.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: FC.white.withValues(alpha: 0.78),
                        height: 1.5,
                      ),
                    ),

                    // ILUSTRAÇÃO
                    const Expanded(
                      child: Center(
                        child: Text(
                          '🐶🐱',
                          style: TextStyle(fontSize: 78),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CARD INFERIOR
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: FC.white,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nome do pet',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FC.textDark,
                      ),
                    ),

                    const SizedBox(height: 10),

                    PillField(
                      hint: 'Ex: Thor, Luna, Mel...',
                      controller: _nameCtrl,
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'Escolha o tipo',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FC.textDark,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CACHORRO
                    PillSelectButton(
                      label: 'Cachorro 🐶',
                      selected: _species == 'Cachorro',
                      onTap: () => _selectSpecies('Cachorro'),
                    ),

                    const SizedBox(height: 12),

                    // GATO
                    PillSelectButton(
                      label: 'Gato 🐱',
                      selected: _species == 'Gato',
                      onTap: () => _selectSpecies('Gato'),
                    ),

                    const SizedBox(height: 34),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FC.blueLight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: FC.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ao continuar você autoriza a geolocalização do aplicativo para encontrar serviços próximos.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: FC.textMid,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 34),

                    // BOTÃO CONTINUAR
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: ready ? _next : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FC.blue,
                          disabledBackgroundColor:
                              FC.blue.withValues(alpha: 0.3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: ScaleTransition(
                          scale: ready
                              ? _arrowScale
                              : const AlwaysStoppedAnimation(1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continuar',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: FC.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: FC.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
