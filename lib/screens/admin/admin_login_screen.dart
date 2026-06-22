import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading  = false;
  bool _obscure  = true;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final res = await AuthService().signIn(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (!res.success) {
      setState(() { _error = res.error; _loading = false; });
    }
    // On success the StreamBuilder in AdminApp redirects automatically.
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FC.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: FC.blue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.pets, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text('Fucinho Admin',
                          style: GoogleFonts.poppins(
                              fontSize: 24, fontWeight: FontWeight.w800, color: FC.textDark)),
                      const SizedBox(height: 4),
                      Text('Painel administrativo',
                          style: GoogleFonts.poppins(fontSize: 14, color: FC.textLight)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                PillField(
                  controller: _emailCtrl,
                  hint: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                PillField(
                  controller: _passCtrl,
                  hint: 'Senha',
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                        color: FC.textLight),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: GoogleFonts.poppins(fontSize: 13, color: FC.error)),
                ],
                const SizedBox(height: 24),
                PillButton(
                  label: 'Entrar',
                  loading: _loading,
                  onTap: _login,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
