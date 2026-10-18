import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'recipes_screen.dart';

/// The four main tabs with the floating green pill navigation bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static HomeShellState? of(BuildContext context) => context.findAncestorStateOfType<HomeShellState>();

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int index = 0;

  void goTo(int i) => setState(() => index = i);

  static const _items = [
    (Icons.room_service_outlined, 'Home'),
    (Icons.menu_book_outlined, 'Recipes'),
    (Icons.history_rounded, 'History'),
    (Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: index,
        children: const [HomeScreen(), RecipesScreen(), HistoryScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: W2T.olive,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _items.length; i++)
                _NavItem(icon: _items[i].$1, label: _items[i].$2, active: i == index, onTap: () => goTo(i)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? W2T.butter : const Color(0xFFC9D0B4);
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
