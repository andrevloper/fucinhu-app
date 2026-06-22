import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/admin_service.dart';
import 'theme/app_theme.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/admin/admin_login_screen.dart';

// ── Executar com: flutter run -d chrome --target lib/main_admin.dart ──
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fucinho Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: StreamBuilder<AuthState>(
        stream: AuthService().authStateChanges,
        builder: (context, snap) {
          final session = snap.data?.session;
          if (session == null && !AuthService().isLoggedIn) {
            return const AdminLoginScreen();
          }
          return const _AdminGuard();
        },
      ),
    );
  }
}

class _AdminGuard extends StatefulWidget {
  const _AdminGuard();

  @override
  State<_AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<_AdminGuard> {
  bool? _isAdmin;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await AdminService().isAdmin();
    if (!mounted) return;
    setState(() => _isAdmin = ok);
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_isAdmin!) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Color(0xFF2236D4)),
              const SizedBox(height: 16),
              const Text('Acesso restrito',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Seu usuário não tem permissão de administrador.',
                  style: TextStyle(color: Color(0xFF8A96A8))),
              const SizedBox(height: 24),
              TextButton(onPressed: _signOut, child: const Text('Sair')),
            ],
          ),
        ),
      );
    }
    return const AdminShell();
  }
}
