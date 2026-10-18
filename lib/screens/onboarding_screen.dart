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
  final _pc = PageController();
  int _page = 0;

  static const _copy = [
    ('Sustainable bites,\ndelightful flavors.', 'Turn the leftovers in your fridge into meals you actually want to eat.'),
    ('Know what you have.', 'Scan your fridge or pick from a list. We remind you before anything goes bad.'),
    ('Cook it before it spoils.', 'Get recipes made from what you already have, even with just a rice cooker.'),
  ];

  void _next() {
    if (_page < 2) {
      _pc.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic);
    } else {
      context.read<AppState>().finishOnboarding();
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: W2T.rust,
      body: Column(
        children: [
          // Top: picture for the current slide
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned.fill(
                    // Swipe or tap Next: the pictures slide sideways between slides.
                    child: PageView(
                      controller: _pc,
                      onPageChanged: (i) => setState(() => _page = i),
                      children: const [_HeroLogo(), _HeroFridge(), _HeroCook()],
                    ),
                  ),
                  if (_page < 2)
                    Positioned(
                      top: 8,
                      right: 12,
                      child: TextButton(
                        onPressed: () => context.read<AppState>().finishOnboarding(),
                        child: const Text('Skip', style: TextStyle(color: W2T.butter, fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom: text + button
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + bottom),
            decoration: const BoxDecoration(
              color: W2T.butter,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? W2T.rust : const Color(0xFFDDB57E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Text fades and slides in when the slide changes.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  child: SizedBox(
                    key: ValueKey(_page),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_copy[_page].$1, style: heading(28)),
                        const SizedBox(height: 10),
                        Text(_copy[_page].$2, style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF5B4A2E))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _page == 2 ? W2T.olive : W2T.rust,
                    foregroundColor: _page == 2 ? W2T.butter : Colors.white,
                  ),
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

/// Slide 1: just the logo, big and centered.
class _HeroLogo extends StatelessWidget {
  const _HeroLogo();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Image.asset('assets/images/logo-cream.webp', width: 240),
      ),
    );
  }
}

/// Slide 2: three fridge items with their expiry.
class _HeroFridge extends StatelessWidget {
  const _HeroFridge();
  @override
  Widget build(BuildContext context) {
    const rows = [
      ('tomato', 'Tomato', '2 days left', true),
      ('chicken', 'Chicken', '3 days left', true),
      ('egg', 'Egg', 'Fresh', false),
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in rows)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Color(0x33321005), blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: W2T.cream, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: IngredientImage(r.$1, size: 44),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(r.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                    Tag(r.$3, bg: r.$4 ? W2T.rustTint : W2T.oliveSoft, fg: r.$4 ? const Color(0xFF8A2A12) : const Color(0xFF2F3A16)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Slide 3: a dish with a "cook tonight" label.
class _HeroCook extends StatelessWidget {
  const _HeroCook();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FoodImage('assets/images/bakmi.webp', size: 240),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: W2T.butter, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('COOK TONIGHT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: W2T.rust, letterSpacing: .6)),
                Text('Bakmi Ayam · 25 min', style: heading(16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
