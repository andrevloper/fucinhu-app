import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'auth_flow_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Logo: fade + scale
  late final AnimationController _logoCtrl;
  late final Animation<double>   _logoFade;
  late final Animation<double>   _logoScale;

  // Tagline: slide up + fade
  late final AnimationController _tagCtrl;
  late final Animation<double>   _tagFade;
  late final Animation<Offset>   _tagSlide;

  // Ilustração: fade
  late final AnimationController _imgCtrl;
  late final Animation<double>   _imgFade;

  // CTA: fade + slide
  late final AnimationController _ctaCtrl;
  late final Animation<double>   _ctaFade;
  late final Animation<Offset>   _ctaSlide;

  // Pulso da seta
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _logoFade  = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoScale = Tween(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));

    _tagCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _tagFade  = CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut);
    _tagSlide = Tween<Offset>(
        begin: const Offset(0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut));

    _imgCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _imgFade = CurvedAnimation(parent: _imgCtrl, curve: Curves.easeIn);

    _ctaCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _ctaFade  = CurvedAnimation(parent: _ctaCtrl, curve: Curves.easeOut);
    _ctaSlide = Tween<Offset>(
        begin: const Offset(0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(parent: _ctaCtrl, curve: Curves.easeOut));

    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 1.0, end: 1.28).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Sequência staggered
    _logoCtrl.forward().then((_) =>
    _tagCtrl.forward().then((_) =>
    _imgCtrl.forward().then((_) =>
    _ctaCtrl.forward())));

    // Auto-navegar após 6 s
    Future.delayed(const Duration(seconds: 6), _go);
  }

  @override
  void dispose() {
    _logoCtrl.dispose(); _tagCtrl.dispose();
    _imgCtrl.dispose(); _ctaCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _go() {
    if (!mounted) return;
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => const AuthFlowScreen(),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFD9A0F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Logo
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Image.asset('assets/images/logo.png',
                      height: 36, color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (_, __, ___) => Text('Fucinho.co',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18))),
                ),
              ),
            ),

            // Headline
            FadeTransition(
              opacity: _tagFade,
              child: SlideTransition(
                position: _tagSlide,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Text('Cheira bem.\nVive melhor.',
                      style: GoogleFonts.poppins(
                          fontSize: 38, fontWeight: FontWeight.w900,
                          color: Colors.white, height: 1.1)),
                ),
              ),
            ),

            // Ilustração cachorro
            Expanded(
              child: FadeTransition(
                opacity: _imgFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                  child: Image.asset('assets/images/dog.png',
                      width: w, fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (_, __, ___) => const Center(
                          child: Text('🐕',
                              style: TextStyle(fontSize: 80)))),
                ),
              ),
            ),

            // CTA
            FadeTransition(
              opacity: _ctaFade,
              child: SlideTransition(
                position: _ctaSlide,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: GestureDetector(
                    onTap: _go,
                    behavior: HitTestBehavior.opaque,
                    child: Row(children: [
                      Text('Vamos\nComeçar',
                          style: GoogleFonts.poppins(
                              fontSize: 34, fontWeight: FontWeight.w900,
                              color: Colors.white, height: 1.1)),
                      const Spacer(),
                      ScaleTransition(
                        scale: _pulse,
                        child: const Icon(Icons.arrow_forward,
                            color: FC.blue, size: 40),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
