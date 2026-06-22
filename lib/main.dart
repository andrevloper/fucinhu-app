import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const FucinhuApp());
}

class FucinhuApp extends StatelessWidget {
  const FucinhuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fucinho.co',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AuthService().isLoggedIn
          ? const _SessionStartup()
          : const SplashScreen(),
    );
  }
}

// Garante profile antes de entrar na Home quando já há sessão ativa.
class _SessionStartup extends StatefulWidget {
  const _SessionStartup();

  @override
  State<_SessionStartup> createState() => _SessionStartupState();
}

class _SessionStartupState extends State<_SessionStartup> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final client = Supabase.instance.client;

    // Tenta renovar o JWT. Se falhar por qualquer motivo (token expirado,
    // rede indisponível, etc.) verifica se o SDK já invalidou a sessão.
    try {
      await client.auth.refreshSession();
    } catch (_) {
      if (!mounted) return;
      // Se o SDK revogou a sessão durante o refresh, redireciona para login.
      if (client.auth.currentUser == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
        return;
      }
      // Erro de rede mas sessão ainda presente: continua e as telas
      // individuais mostrarão mensagem de erro caso as queries falhem.
    }

    await AuthService().ensureProfile();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(userName: AuthService().displayName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
