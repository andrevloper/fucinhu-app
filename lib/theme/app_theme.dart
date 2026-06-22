import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────
// CORES — extraídas da imagem de referência
// ─────────────────────────────────────────
class FC {
  // Azul principal (fundo hero, botões)
  static const blue        = Color(0xFF2236D4);
  static const blueDark    = Color(0xFF1A2BA8);
  static const blueLight   = Color(0xFFE8ECFF);

  // Branco / superfícies
  static const white       = Color(0xFFFFFFFF);
  static const bg          = Color(0xFFF4F6FF);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF0F3FF);

  // Texto
  static const textDark    = Color(0xFF1A2332);
  static const textMid     = Color(0xFF4A5568);
  static const textLight   = Color(0xFF8A96A8);
  static const textOnBlue  = Color(0xFFFFFFFF);
  static const textOnBlue2 = Color(0xCCFFFFFF); // 80% white

  // Bordas
  static const border      = Color(0xFF2236D4); // bordas dos campos = azul
  static const divider     = Color(0xFFE2E8F0);

  // Categorias serviços
  static const secondary   = Color(0xFFF5A623);  // âmbar
  static const catVet      = Color(0xFF4A90D9);
  static const catShop     = Color(0xFF2DBE8A);
  static const catBanho    = Color(0xFF9B72CF);
  static const catHotel    = Color(0xFFF5A623);
  static const catPasseio  = Color(0xFFE05252);
  static const catAdest    = Color(0xFF2BBFBF);

  // Status
  static const success     = Color(0xFF2DBE8A);
  static const error       = Color(0xFFE05252);
  static const warning     = Color(0xFFF5A623);
}

// ─────────────────────────────────────────
// RAIOS E SOMBRAS
// ─────────────────────────────────────────
class FR {
  static const pill  = 50.0;
  static const card  = 20.0;
  static const sm    = 10.0;
  static const xl    = 28.0;
}

class FS {
  static List<BoxShadow> get card => [
    BoxShadow(color: const Color(0xFF2236D4).withValues(alpha: 0.08),
        blurRadius: 20, offset: const Offset(0, 6)),
  ];
  static List<BoxShadow> get fab => [
    BoxShadow(color: const Color(0xFF2236D4).withValues(alpha: 0.40),
        blurRadius: 24, spreadRadius: 2, offset: const Offset(0, 8)),
  ];
}

// ─────────────────────────────────────────
// TEMA GLOBAL
// ─────────────────────────────────────────
class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: FC.blue,
        primary: FC.blue,
        surface: FC.surface,
        error: FC.error,
      ),
      scaffoldBackgroundColor: FC.bg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: FC.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: FC.textDark),
        titleTextStyle: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w700, color: FC.textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FC.blue,
          foregroundColor: FC.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FR.pill)),
          textStyle: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FC.blue,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FR.pill)),
          side: const BorderSide(color: FC.blue, width: 1.5),
          textStyle: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FC.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        // Campos com borda azul arredondada — igual ao protótipo
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FR.pill),
          borderSide: const BorderSide(color: FC.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FR.pill),
          borderSide: const BorderSide(color: FC.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FR.pill),
          borderSide: const BorderSide(color: FC.blue, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FR.pill),
          borderSide: const BorderSide(color: FC.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.poppins(
            fontSize: 15, color: FC.blue.withValues(alpha: 0.55)),
        labelStyle:
            GoogleFonts.poppins(fontSize: 14, color: FC.textMid),
      ),
      cardTheme: CardThemeData(
        color: FC.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FR.card),
          side: const BorderSide(color: FC.divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: FC.surface,
        selectedItemColor: FC.blue,
        unselectedItemColor: FC.textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
      ),
    );
  }
}
