import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../services/auth_service.dart';
import 'pet_form_screen.dart';
import 'auth_flow_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterScreen> {
  final _form        = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _terms   = false;
  bool _loading = false;
  int  _step    = 0; // 0 = dados pessoais | 1 = senha + termos

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_form.currentState!.validate()) return;

    // Step 0 → step 1: dados pessoais → senha
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }

    // Step 1 → criar conta (com validação de termos)
    if (_step == 1) {
      if (!_terms) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Aceite os termos para continuar.',
              style: GoogleFonts.poppins(color: FC.white)),
          backgroundColor: FC.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        return;
      }

      setState(() => _loading = true);
      final result = await AuthService().signUp(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        phone: _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _loading = false);

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.error ?? 'Erro ao criar conta.',
              style: GoogleFonts.poppins(color: FC.white)),
          backgroundColor: FC.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        return;
      }

      final firstName = result.displayName ??
          _nameCtrl.text.trim().split(' ').first;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              PetFormScreen(userName: firstName.isNotEmpty ? firstName : 'Tutor'),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return LoadingOverlay(
      loading: _loading,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: FC.blue,
        body: Column(
          children: [

            // ── Header azul ──────────────────────────────────────
            Container(
              color: FC.blue,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Botão voltar
                      GestureDetector(
                        onTap: _step >= 1
                            ? () => setState(() => _step = _step - 1)
                            : () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back,
                            color: FC.white, size: 26),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _step == 0 ? 'Crie sua conta' : 'Defina sua senha',
                        style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: FC.white),
                      ),
                      const SizedBox(height: 10),
                      // Barra de progresso 2 etapas
                      Row(
                        children: List.generate(2, (i) => Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(right: i < 1 ? 6 : 0),
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

            // ── Card branco ───────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5FF),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // ══ ETAPA 0: Dados pessoais ════════════════
                        if (_step == 0) ...[
                          PillField(
                            hint: 'Nome e sobrenome',
                            controller: _nameCtrl,
                            validator: (v) =>
                                v != null && v.trim().length >= 3
                                    ? null : 'Nome muito curto',
                          ),
                          const SizedBox(height: 14),
                          PillField(
                            hint: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailCtrl,
                            validator: (v) =>
                                v != null && v.contains('@')
                                    ? null : 'E-mail inválido',
                          ),
                          const SizedBox(height: 14),
                          PillField(
                            hint: 'Telefone',
                            keyboardType: TextInputType.phone,
                            controller: _phoneCtrl,
                            validator: (v) =>
                                v != null && v.length >= 10
                                    ? null : 'Telefone inválido',
                          ),
                          const SizedBox(height: 28),

                          // Botão Continuar
                          _PinkButton(label: 'Continuar', onTap: _next),
                          const SizedBox(height: 16),

                          // Já tenho uma conta
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Já tem uma conta? ',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, color: FC.textMid)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) =>
                                        const AuthFlowScreen(),
                                    transitionsBuilder: (_, a, __, child) =>
                                        FadeTransition(opacity: a, child: child),
                                    transitionDuration:
                                        const Duration(milliseconds: 300),
                                  ),
                                ),
                                child: Text('Entrar',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: FC.blue)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Ilustração tutora + gato no rodapé desta etapa
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/tutor_cat.png',
                              width: double.infinity,
                              height: screenH * 0.25,
                              fit: BoxFit.cover,
                              alignment: Alignment.bottomCenter,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],

                        // ══ ETAPA 1: Senha + Termos ═══════════════════════
                        if (_step == 1) ...[
                          // Campos de senha
                          PillField(
                            hint: 'Senha',
                            obscure: _obscurePass,
                            controller: _passCtrl,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: FC.textLight, size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePass = !_obscurePass),
                            ),
                            validator: (v) =>
                                v != null && v.length >= 6
                                    ? null : 'Mínimo 6 caracteres',
                          ),
                          const SizedBox(height: 14),
                          PillField(
                            hint: 'Confirmar senha',
                            obscure: _obscureConfirm,
                            controller: _confirmCtrl,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: FC.textLight, size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                            validator: (v) =>
                                v == _passCtrl.text
                                    ? null : 'Senhas não coincidem',
                          ),
                          const SizedBox(height: 28),

                          // Checkbox termos
                          GestureDetector(
                            onTap: () =>
                                setState(() => _terms = !_terms),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 22, height: 22,
                                  decoration: BoxDecoration(
                                    color: _terms
                                        ? FC.blue : Colors.transparent,
                                    border: Border.all(
                                        color: _terms ? FC.blue : FC.divider,
                                        width: 1.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: _terms
                                      ? const Icon(Icons.check,
                                          color: FC.white, size: 14)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: FC.textMid),
                                      children: [
                                        const TextSpan(
                                            text: 'Li e aceito os '),
                                        TextSpan(
                                          text: 'Termos de Uso',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: FC.blue),
                                        ),
                                        const TextSpan(text: ' e a '),
                                        TextSpan(
                                          text: 'Política de Privacidade',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: FC.blue),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Botão criar conta
                          PillButton(label: 'Criar conta', onTap: _next),
                          const SizedBox(height: 24),

                          // Ilustração tutora + gato no rodapé
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/tutor_cat.png',
                              width: double.infinity,
                              height: screenH * 0.2,
                              fit: BoxFit.cover,
                              alignment: Alignment.bottomCenter,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],

                      ],
                    ),
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

// ── Botão azul escuro com texto ROSA sublinhado ────────────────────
class _PinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PinkButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3347DD),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FR.pill)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFF69B4),
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFFFF69B4),
          ),
        ),
      ),
    );
  }
}
