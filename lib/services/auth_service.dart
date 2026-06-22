import 'package:supabase_flutter/supabase_flutter.dart';

class AuthResult {
  final bool success;
  final String? displayName;
  final String? error;
  final bool emailNotConfirmed;
  final bool emailAlreadyExists;
  final bool isNewGoogleUser;

  const AuthResult({
    required this.success,
    this.displayName,
    this.error,
    this.emailNotConfirmed = false,
    this.emailAlreadyExists = false,
    this.isNewGoogleUser = false,
  });
}

class AuthService {
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;
  AuthService._();

  SupabaseClient get _db => Supabase.instance.client;

  User? get currentUser => _db.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<AuthState> get authStateChanges => _db.auth.onAuthStateChange;

  String get displayName {
    final meta = currentUser?.userMetadata;
    final name = meta?['name'] as String? ?? meta?['full_name'] as String?;
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    return _nameFromEmail(currentUser?.email ?? '');
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first;
    final parts = local
        .replaceAll(RegExp(r'[0-9_\-+]'), ' ')
        .split('.')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .toList();
    return parts.isNotEmpty ? parts.first : 'Tutor';
  }

  // ── Verificar se e-mail já existe via RPC (SECURITY DEFINER) ────────
  Future<bool> emailExists(String email) async {
    try {
      final result = await _db.rpc(
        'check_email_exists',
        params: {'email_to_check': email.trim().toLowerCase()},
      );
      return result as bool? ?? false;
    } catch (_) {
      return false; // se RPC não existir, permite continuar
    }
  }

  // ── Cadastro ──────────────────────────────────────────────────────
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      // Verificar se e-mail já está cadastrado
      final exists = await emailExists(email);
      if (exists) {
        return const AuthResult(
          success: false,
          emailAlreadyExists: true,
          error: 'Este e-mail já está cadastrado. Faça login.',
        );
      }

      final res = await _db.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim(), 'phone': phone?.trim() ?? ''},
      );

      if (res.user == null) {
        return const AuthResult(
            success: false, error: 'Não foi possível criar a conta.');
      }

      // Nome e telefone ficam no userMetadata do Supabase Auth.
      // O profile só é criado no primeiro login, após o e-mail ser confirmado.

      // Supabase exige confirmação de e-mail por padrão
      final firstName = name.trim().split(' ').first;
      return AuthResult(
        success: true,
        displayName: firstName,
        emailNotConfirmed:
            res.session == null, // sem sessão = aguardando confirmação
      );
    } on AuthException catch (e) {
      return AuthResult(success: false, error: _translate(e.message));
    } catch (e) {
      return AuthResult(success: false, error: 'Erro inesperado: $e');
    }
  }

  // ── Login com e-mail + senha ───────────────────────────────────────
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _db.auth
          .signInWithPassword(email: email.trim(), password: password);

      if (res.user == null) {
        return const AuthResult(
            success: false, error: 'E-mail ou senha incorretos.');
      }

      // Garante que o perfil existe com nome e telefone do cadastro
      try {
        final uid = res.user!.id;
        final existing = await _db
            .from('profiles')
            .select('id')
            .eq('id', uid)
            .maybeSingle();
        if (existing == null) {
          final meta = res.user!.userMetadata;
          final name =
              (meta?['name'] ?? meta?['full_name'] ?? '').toString().trim();
          final phone = (meta?['phone'] ?? '').toString().trim();
          await _db.from('profiles').insert({
            'id': uid,
            'name': name,
            'phone': phone,
          });
        }
      } catch (_) {}

      return AuthResult(success: true, displayName: displayName);
    } on AuthException catch (e) {
      return AuthResult(success: false, error: _translate(e.message));
    } catch (e) {
      return const AuthResult(success: false, error: 'Erro de conexão.');
    }
  }

  // ── Login com Google via Supabase OAuth ─────────────────────────
  // Requer configuração do Google OAuth no painel do Supabase:
  // Authentication → Providers → Google → habilitar + inserir Client ID e Secret
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Supabase abre o fluxo OAuth do Google nativamente
      await _db.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.fucinhu://login-callback/',
        queryParams: {
          'access_type': 'offline',
          'prompt': 'select_account', // sempre mostrar seletor de conta
        },
      );
      // A sessão é configurada automaticamente via deep link
      // Aguardar atualização do estado de auth
      await Future.delayed(const Duration(seconds: 2));
      if (currentUser != null) {
        final name = displayName;
        final uid = currentUser!.id;
        // Verifica se perfil já existia antes desta autenticação
        bool isNew = false;
        try {
          final existing = await _db
              .from('profiles')
              .select('id')
              .eq('id', uid)
              .maybeSingle();
          isNew = existing == null;
          await _db.from('profiles').upsert({
            'id': uid,
            'name': currentUser!.userMetadata?['full_name'] ?? name,
            'phone': '',
          });
        } catch (_) {}
        return AuthResult(
            success: true, displayName: name, isNewGoogleUser: isNew);
      }
      return const AuthResult(
          success: false, error: 'Login com Google não concluído.');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('abort')) {
        return const AuthResult(success: false, error: 'Login cancelado.');
      }
      return AuthResult(success: false, error: 'Erro com Google: $e');
    }
  }

  // ── Reenviar e-mail de confirmação ────────────────────────────────
  Future<void> resendConfirmation(String email) async {
    try {
      await _db.auth.resend(type: OtpType.signup, email: email.trim());
    } catch (_) {}
  }

  // ── Recuperar senha ────────────────────────────────────────────────
  Future<AuthResult> resetPassword(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      return const AuthResult(success: false, error: 'Digite um e-mail válido.');
    }
    try {
      await _db.auth.resetPasswordForEmail(
        trimmed,
        redirectTo: 'io.supabase.fucinhu://reset-callback/',
      );
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, error: _translate(e.message));
    } catch (e) {
      return const AuthResult(success: false, error: 'Erro de conexão.');
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _db.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    return await _db.from('profiles').select().eq('id', uid).maybeSingle();
  }

  // Garante que o profile existe; cria a partir do userMetadata se não existir.
  Future<void> ensureProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return;
    try {
      final existing = await _db
          .from('profiles')
          .select('id')
          .eq('id', uid)
          .maybeSingle();
      if (existing == null) {
        final meta = currentUser?.userMetadata;
        await _db.from('profiles').insert({
          'id': uid,
          'name': (meta?['name'] ?? meta?['full_name'] ?? '').toString().trim(),
          'phone': (meta?['phone'] ?? '').toString().trim(),
        });
      }
    } catch (_) {}
  }

  Future<AuthResult> updateProfile({
    required String name,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      final uid = currentUser?.id;
      if (uid == null) {
        return const AuthResult(success: false, error: 'Não autenticado.');
      }
      // upsert: cria o profile se não existir, atualiza se existir
      await _db.from('profiles').upsert({
        'id': uid,
        'name': name.trim(),
        'phone': phone?.trim() ?? '',
        if (photoUrl != null) 'photo_url': photoUrl,
      });
      await _db.auth.updateUser(UserAttributes(data: {'name': name.trim()}));
      return const AuthResult(success: true);
    } catch (e) {
      return AuthResult(success: false, error: '$e');
    }
  }

  String _translate(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid') ||
        m.contains('wrong') ||
        m.contains('credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (m.contains('email already') || m.contains('already registered')) {
      return 'Este e-mail já está cadastrado. Faça login.';
    }
    if (m.contains('not confirmed')) {
      return 'Confirme seu e-mail antes de entrar. Verifique sua caixa de entrada.';
    }
    if (m.contains('weak') || m.contains('password')) {
      return 'Senha muito fraca (mínimo 6 caracteres).';
    }
    if (m.contains('network') || m.contains('connection')) {
      return 'Sem conexão com a internet.';
    }
    if (m.contains('user not found') || m.contains('no user')) {
      return 'Nenhuma conta encontrada com este e-mail.';
    }
    return msg;
  }
}
