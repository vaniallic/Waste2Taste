import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  static const _copy = [
    ('Sustainable bites, delightful flavors.', 'Turn the leftovers in your fridge into meals you actually want to eat.'),
    ('Know what you have.', 'Scan your fridge or pick from a list. We remind you before anything goes bad.'),
    ('Cook it before it spoils.', 'Get recipes made from what you already have, even with just a rice cooker.'),
  ];

  void _next() {
    if (_page < 2) {
      _pages.jumpToPage(_page + 1);
      context.read<AppState>().finishOnboarding();
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: W2T.rust,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: const [_HeroLogo(), _HeroFridge(), _HeroCook()],
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () => context.read<AppState>().finishOnboarding(),
                      child: const Text('Skip', style: TextStyle(color: W2T.butter, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(28, 30, 28, 24 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(color: W2T.butter, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      AnimatedContainer(
                        duration: Duration.zero,
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _page ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(color: i == _page ? W2T.rust : const Color(0xFFD9B07A), borderRadius: BorderRadius.circular(4)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: Duration.zero,
                  child: Column(
                    key: ValueKey(_page),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_copy[_page].$1, style: heading(30)),
                      const SizedBox(height: 10),
                      Text(_copy[_page].$2, style: const TextStyle(fontSize: 15, height: 1.55, color: Color(0xFF5B4A2E))),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  style: _page == 2 ? null : FilledButton.styleFrom(backgroundColor: W2T.rust, foregroundColor: Colors.white),
                  onPressed: _next,
                  child: Text(_page == 2 ? 'Get Started' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc();
  @override
  Widget build(BuildContext context) =>
      Container(width: 300, height: 300, decoration: const BoxDecoration(color: W2T.rustSoft, shape: BoxShape.circle));
}

class _HeroLogo extends StatelessWidget {
  const _HeroLogo();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Image.asset('assets/images/logo-cream.webp', width: 200),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                const _Disc(),
                Image.asset('assets/images/friedrice.webp', width: 250),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroFridge extends StatelessWidget {
  const _HeroFridge();
  @override
  Widget build(BuildContext context) {
    const rows = [
      ('tomato', 'Tomato', '2 days left', true),
      ('chicken', 'Chicken', '3 days left', true),
      ('egg', 'Egg', 'Fresh', false),
    ];
    return Stack(
      alignment: Alignment.center,
      children: [
        const _Disc(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in rows)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 72,
                  padding: const EdgeInsets.only(left: 8, right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [BoxShadow(color: Color(0x40321005), blurRadius: 24, offset: Offset(0, 12))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: W2T.cream, borderRadius: BorderRadius.circular(16)),
                        alignment: Alignment.center,
                        child: IngredientImage(r.$1, size: 48),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(r.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                      Tag(r.$3, bg: r.$4 ? W2T.rustTint : W2T.oliveSoft, fg: r.$4 ? const Color(0xFF8A2A12) : const Color(0xFF2F3A16)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCook extends StatelessWidget {
  const _HeroCook();
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const _Disc(),
        const FoodImage('assets/images/bakmi.webp', size: 280, turns: -0.14),
        Positioned(
          right: 24,
          bottom: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: W2T.butter, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('COOK TONIGHT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: W2T.rust, letterSpacing: .5)),
                Text('Bakmi Ayam · 25 min', style: heading(16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
