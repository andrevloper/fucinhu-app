import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../services/auth_service.dart';
import 'auth_flow_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _form      = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _goHome(String name) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MainScreen(userName: name),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: FC.white)),
      backgroundColor: FC.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final res = await AuthService()
        .signIn(email: _emailCtrl.text, password: _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    res.success
        ? _goHome(res.displayName ?? 'Tutor')
        : _showError(res.error ?? 'Erro ao fazer login.');
  }

  Future<void> _loginGoogle() async {
    setState(() => _loading = true);
    final res = await AuthService().signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.success) {
      _goHome(res.displayName ?? 'Tutor');
    } else if (res.error != null && res.error!.isNotEmpty && !res.error!.contains('cancelado')) {
      _showError(res.error!);
    }
  }

  void _forgotPass() {
    final ctrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FR.xl)),
        title: Text('Recuperar senha',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Digite seu e-mail:',
              style: GoogleFonts.poppins(fontSize: 13)),
          const SizedBox(height: 12),
          PillField(hint: 'E-mail', controller: ctrl,
              keyboardType: TextInputType.emailAddress),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: FC.textMid)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await AuthService().resetPassword(ctrl.text);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  res.success
                      ? 'Link enviado para ${ctrl.text}'
                      : (res.error ?? 'Erro'),
                  style: GoogleFonts.poppins(color: FC.white),
                ),
                backgroundColor: res.success ? FC.blue : FC.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;

    return LoadingOverlay(
      loading: _loading,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: FC.blue,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [

              // ── Hero azul — exatamente como estava ─────────────
              // Altura proporcional: ~40% da tela para o header
              Container(
                height: screenH * 0.33,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: FC.blue,
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 44,
                          color: FC.white,
                          colorBlendMode: BlendMode.srcIn,
                          errorBuilder: (_, __, ___) => Text('Fucinho.co',
                              style: GoogleFonts.poppins(
                                  color: FC.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22)),
                        ),
                        const SizedBox(height: 14),
                        Text('Bem-vindo\nde volta! 👋',
                            style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: FC.white,
                                height: 1.15)),
                        const SizedBox(height: 6),
                        Text('Encontre serviços pet perto de você',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: FC.white.withValues(alpha: 0.75))),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Card branco — formulário compacto ──────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: FC.bg,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text('Entrar na conta',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: FC.textDark)),
                        const SizedBox(height: 16),

                        // E-mail
                        PillField(
                          hint: 'E-mail',
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailCtrl,
                          validator: (v) => v != null && v.contains('@')
                              ? null : 'E-mail inválido',
                        ),
                        const SizedBox(height: 10),

                        // Senha
                        PillField(
                          hint: 'Senha',
                          obscure: _obscure,
                          controller: _passCtrl,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: FC.textLight, size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) => v != null && v.length >= 6
                              ? null : 'Mínimo 6 caracteres',
                        ),

                        // Esqueci senha — compacto
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgotPass,
                            style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 4)),
                            child: Text('Esqueci minha senha',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: FC.blue)),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Botão entrar
                        PillButton(label: 'Entrar', onTap: _login),
                        const SizedBox(height: 12),

                        const OrDivider(),
                        const SizedBox(height: 12),

                        // Google
                        GoogleButton(onTap: _loginGoogle),

                        const Spacer(),

                        // Criar conta — rodapé
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Não tem conta? ',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, color: FC.textMid)),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const RegisterScreen())),
                                child: Text('Criar conta',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: FC.blue)),
                              ),
                            ],
                          ),
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
    );
  }
}
