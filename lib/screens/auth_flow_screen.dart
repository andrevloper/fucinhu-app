import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../services/auth_service.dart';
import '../services/pet_service.dart';
import 'main_screen.dart';
import 'pet_form_screen.dart';

// ══════════════════════════════════════════════════════════════════
// TELA INICIAL — Login limpo (email + senha + Google)
// ══════════════════════════════════════════════════════════════════
class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({super.key});
  @override
  State<AuthFlowScreen> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlowScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loadingEmail = false;
  bool _loadingGoogle = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

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

  // ── Login com e-mail e senha ───────────────────────────────────
  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loadingEmail = true);
    final res = await AuthService()
        .signIn(email: _emailCtrl.text, password: _passCtrl.text);
    if (!mounted) return;
    setState(() => _loadingEmail = false);
    if (res.success) {
      final name = res.displayName ?? 'Tutor';
      final pets = await PetService().getPets();
      if (!mounted) return;
      if (pets.isEmpty) {
        Navigator.pushAndRemoveUntil(
            context, _fade(PetFormScreen(userName: name)), (_) => false);
      } else {
        _goHome(name);
      }
    } else {
      _snack(res.error ?? 'E-mail ou senha incorretos.', FC.error);
    }
  }

  // ── Login com Google ───────────────────────────────────────────
  Future<void> _doGoogle() async {
    setState(() => _loadingGoogle = true);
    final res = await AuthService().signInWithGoogle();
    if (!mounted) return;
    setState(() => _loadingGoogle = false);
    if (res.success) {
      if (res.isNewGoogleUser) {
        Navigator.pushReplacement(context,
            _fade(PetFormScreen(userName: res.displayName ?? 'Tutor')));
      } else {
        _goHome(res.displayName ?? 'Tutor');
      }
    } else if (res.error != null && res.error != 'Login cancelado.') {
      _snack(res.error!, FC.error);
    }
  }

  // ── Esqueci senha ──────────────────────────────────────────────
  void _forgotPass() {
    final ctrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Recuperar senha',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Enviamos um link para seu e-mail:',
                    style:
                        GoogleFonts.poppins(fontSize: 13, color: FC.textMid)),
                const SizedBox(height: 12),
                PillField(
                    hint: 'E-mail',
                    controller: ctrl,
                    keyboardType: TextInputType.emailAddress),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar',
                        style: GoogleFonts.poppins(color: FC.textMid))),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await AuthService().resetPassword(ctrl.text);
                    if (!mounted) return;
                    _snack('Link enviado para ${ctrl.text}', FC.blue);
                  },
                  style:
                      ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                  child: const Text('Enviar'),
                ),
              ],
            ));
  }

  void _goHome(String name) => Navigator.pushAndRemoveUntil(
      context, _fade(MainScreen(userName: name)), (_) => false);

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: FC.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return LoadingOverlay(
      loading: _loadingGoogle,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: FC.blue,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: Column(children: [
              // ── Topo azul — logo ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                child: Column(children: [
                  Image.asset('assets/images/logo.png',
                      width: size.width * 0.55,
                      color: FC.white,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (_, __, ___) => Text('Fucinho.co',
                          style: GoogleFonts.poppins(
                              color: FC.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 28))),
                  const SizedBox(height: 6),
                  Text('Bem-vindo de volta! 👋',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: FC.white.withValues(alpha: 0.80))),
                ]),
              ),

              // ── Card branco ───────────────────────────────
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5FF),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // E-mail
                          _Field(
                            controller: _emailCtrl,
                            hint: 'E-mail',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v != null && v.contains('@')
                                ? null
                                : 'E-mail inválido',
                          ),
                          const SizedBox(height: 12),

                          // Senha
                          _Field(
                            controller: _passCtrl,
                            hint: 'Senha',
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: FC.textLight,
                                  size: 20),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) => v != null && v.length >= 6
                                ? null
                                : 'Mínimo 6 caracteres',
                          ),

                          // Esqueceu
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPass,
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 0, vertical: 4)),
                              child: Text('Esqueceu a senha?',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: FC.blue)),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Entrar
                          _loadingEmail
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: FC.blue, strokeWidth: 2.5))
                              : PillButton(label: 'Entrar', onTap: _doLogin),
                          const SizedBox(height: 20),

                          // Divisor
                          _Divider(),
                          const SizedBox(height: 16),

                          // Google
                          _GoogleBtn(onTap: _doGoogle),
                          const SizedBox(height: 24),

                          // Criar conta
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Não tem conta? ",
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, color: FC.textMid)),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                    context, _slide(const RegisterScreen())),
                                child: Text('Criar conta',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFE91E8C))),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TELA DE CADASTRO — 2 etapas: dados pessoais | senha + termos
// ══════════════════════════════════════════════════════════════════
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterScreen> {
  final _formKey0 = GlobalKey<FormState>(); // etapa 0: dados pessoais
  final _formKey1 = GlobalKey<FormState>(); // etapa 1: senha + termos
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _terms      = false;
  bool _loading    = false;
  bool _emailTaken = false; // e-mail já cadastrado
  int  _step       = 0; // 0 = dados pessoais | 1 = senha + termos

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(() {
      if (_emailTaken) setState(() => _emailTaken = false);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step == 0) {
      if (!_formKey0.currentState!.validate()) return;

      // Bloqueia avanço se e-mail já estiver em uso
      setState(() => _loading = true);
      final exists = await AuthService().emailExists(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() => _loading = false);

      if (exists) {
        setState(() => _emailTaken = true);
        _formKey0.currentState?.validate();
        return;
      }

      setState(() => _step = 1);
      return;
    }

    if (!_formKey1.currentState!.validate()) return;
    if (!_terms) {
      _snack('Aceite os termos para continuar.', FC.warning);
      return;
    }

    setState(() => _loading = true);

    final res = await AuthService().signUp(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone: _phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (!res.success) {
      _snack(res.error ?? 'Erro ao criar conta.', FC.error);
      return;
    }

    if (res.emailNotConfirmed) {
      _showConfirmDialog();
    } else {
      final name = res.displayName ?? _nameCtrl.text.trim().split(' ').first;
      Navigator.pushAndRemoveUntil(
          context,
          _fade(PetFormScreen(userName: name.isNotEmpty ? name : 'Tutor')),
          (_) => false);
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.mark_email_unread_rounded,
            color: FC.blue, size: 52),
        title: Text('Confirme seu e-mail',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Enviamos um link de ativação para',
              style: GoogleFonts.poppins(fontSize: 13, color: FC.textMid),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(_emailCtrl.text.trim(),
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: FC.textDark),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('Clique no link para ativar sua conta.',
              style: GoogleFonts.poppins(fontSize: 13, color: FC.textMid),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () async {
              await AuthService().resendConfirmation(_emailCtrl.text.trim());
              if (!mounted) return;
              _snack('E-mail reenviado!', FC.blue);
            },
            child: Text('Reenviar e-mail',
                style: GoogleFonts.poppins(
                    color: FC.blue, fontWeight: FontWeight.w600)),
          ),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                    context, _fade(const AuthFlowScreen()), (_) => false);
              },
              child: const Text('Entendido'),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: FC.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      loading: _loading,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: FC.blue,
        body: Column(children: [
          // ── Header azul ──────────────────────────────────
          Container(
            color: FC.blue,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _step == 1
                          ? () => setState(() => _step = 0)
                          : () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back,
                          color: FC.white, size: 26),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _step == 0 ? 'Criar conta' : 'Defina sua senha',
                      style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: FC.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _step == 0
                          ? 'Preencha seus dados para começar'
                          : 'Crie uma senha segura para sua conta',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: FC.white.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: 12),
                    // Barra de progresso (2 etapas)
                    Row(
                      children: List.generate(2, (i) => Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i == 0 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: i <= _step
                                ? FC.white
                                : FC.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Card branco ───────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Builder(builder: (ctx) {
                final keyboardUp = MediaQuery.of(ctx).viewInsets.bottom > 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: _step == 0 ? _buildStep0() : _buildStep1(),
                    ),
                    if (!keyboardUp)
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Image.asset(
                            'assets/images/tutor_cat.png',
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Etapa 0: Nome, E-mail, Telefone ──────────────────────────────
  Widget _buildStep0() {
    return Form(
      key: _formKey0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(
            controller: _nameCtrl,
            hint: 'Nome completo',
            icon: Icons.person_outline,
            validator: (v) => v != null && v.trim().length >= 3
                ? null : 'Nome muito curto',
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _emailCtrl,
            hint: 'E-mail',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || !v.contains('@')) return 'E-mail inválido';
              if (_emailTaken) return 'Este e-mail já está cadastrado. Faça login.';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _phoneCtrl,
            hint: 'Telefone / WhatsApp',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => v != null && v.length >= 10
                ? null : 'Telefone inválido',
          ),
          const SizedBox(height: 20),
          PillButton(label: 'Continuar', onTap: _next, foregroundColor: const Color(0xFFDCA6EF)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Já tem conta? ',
                  style: GoogleFonts.poppins(fontSize: 13, color: FC.textMid)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text('Entrar',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: FC.blue)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Etapa 1: Senha, Confirmar, Termos ────────────────────────────
  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(
            controller: _passCtrl,
            hint: 'Senha',
            icon: Icons.lock_outline,
            obscure: _obscurePass,
            suffix: IconButton(
              icon: Icon(
                  _obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: FC.textLight,
                  size: 20),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
            validator: (v) => v != null && v.length >= 6
                ? null : 'Mínimo 6 caracteres',
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _confirmCtrl,
            hint: 'Confirmar senha',
            icon: Icons.lock_outline,
            obscure: _obscureConfirm,
            suffix: IconButton(
              icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: FC.textLight,
                  size: 20),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) => v == _passCtrl.text
                ? null : 'As senhas não coincidem',
          ),
          const SizedBox(height: 16),
          // Termos
          GestureDetector(
            onTap: () => setState(() => _terms = !_terms),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _terms ? FC.blue : Colors.transparent,
                    border: Border.all(
                        color: _terms ? FC.blue : FC.divider, width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _terms
                      ? const Icon(Icons.check, color: FC.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: FC.textMid),
                      children: [
                        const TextSpan(text: 'Li e aceito os '),
                        TextSpan(
                            text: 'Termos de Uso',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: FC.blue)),
                        const TextSpan(text: ' e a '),
                        TextSpan(
                            text: 'Política de Privacidade',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: FC.blue)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PillButton(label: 'Criar conta', onTap: _next, foregroundColor: const Color(0xFFDCA6EF)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Componentes compartilhados
// ══════════════════════════════════════════════════════════════════

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.poppins(fontSize: 14, color: FC.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: FC.textLight),
          prefixIcon: Icon(icon, color: FC.textLight, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: FC.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FR.pill),
              borderSide: const BorderSide(color: FC.border, width: 1.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FR.pill),
              borderSide: const BorderSide(color: FC.border, width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FR.pill),
              borderSide: const BorderSide(color: FC.blue, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FR.pill),
              borderSide: const BorderSide(color: FC.error, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FR.pill),
              borderSide: const BorderSide(color: FC.error, width: 2)),
        ),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Divider(
                color: FC.textLight.withValues(alpha: 0.4), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou',
              style: GoogleFonts.poppins(fontSize: 12, color: FC.textLight)),
        ),
        Expanded(
            child: Divider(
                color: FC.textLight.withValues(alpha: 0.4), thickness: 1)),
      ]);
}

class _GoogleBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: FC.white,
            side: const BorderSide(color: FC.divider, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FR.pill)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
                width: 22,
                height: 22,
                child: CustomPaint(painter: _GPainter())),
            const SizedBox(width: 10),
            Text('Continuar com Google',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FC.textDark)),
          ]),
        ),
      );
}

class _GPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2, cy = s.height / 2, r = s.width / 2;
    final p = Paint()..style = PaintingStyle.fill;
    p.color = const Color(0xFF4285F4);
    c.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r), -0.3, 2.0, true, p);
    p.color = const Color(0xFFEA4335);
    c.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r), 1.7, 1.7, true, p);
    p.color = const Color(0xFFFBBC05);
    c.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r), 3.4, 0.9, true, p);
    p.color = const Color(0xFF34A853);
    c.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r), 4.3, 0.9, true, p);
    p.color = Colors.white;
    c.drawCircle(Offset(cx, cy), r * 0.65, p);
    final tp = TextPainter(
      text: TextSpan(
          text: 'G',
          style: TextStyle(
              color: const Color(0xFF4285F4),
              fontSize: s.width * 0.55,
              fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_) => false;
}

PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) =>
        FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 400));

PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
    transitionDuration: const Duration(milliseconds: 320));
