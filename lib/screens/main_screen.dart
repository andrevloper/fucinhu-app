import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'pets_list_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final String userName;
  const MainScreen({super.key, required this.userName});

  @override
  State<MainScreen> createState() => _MainState();
}

class _MainState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _idx = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _tap(int i) {
    if (i == _idx) return;
    _fadeCtrl.reset();
    setState(() => _idx = i);
    _fadeCtrl.forward();
  }

  late final _screens = [
    HomeScreen(userName: widget.userName),
    const MapScreen(),
    const PetsListScreen(),
    const ProfileScreen(),
  ];

  static const _items = [
    (icon: Icons.home_outlined,        activeIcon: Icons.home_rounded,        label: 'Início'),
    (icon: Icons.map_outlined,         activeIcon: Icons.map_rounded,         label: 'Mapa'),
    (icon: Icons.pets_outlined,        activeIcon: Icons.pets,                label: 'Meu Pets'),
    (icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,   label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      extendBody: true,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: IndexedStack(index: _idx, children: _screens),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomPad),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: FC.white,
            borderRadius: BorderRadius.circular(FR.xl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: FC.blue.withValues(alpha: 0.06),
                blurRadius: 40,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = _idx == i;
              final item = _items[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _tap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: active
                            ? Icon(item.activeIcon,
                                key: ValueKey('a$i'),
                                color: FC.blue, size: 26)
                            : Icon(item.icon,
                                key: ValueKey('i$i'),
                                color: FC.textLight, size: 24),
                      ),
                      const SizedBox(height: 2),
                      Text(item.label,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w400,
                            color: active ? FC.blue : FC.textLight,
                          )),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(top: 3),
                        width: active ? 18 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: FC.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
