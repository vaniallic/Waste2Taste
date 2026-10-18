import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/sample_data.dart';
import '../theme.dart';

/// Rust header on top, butter-coloured rounded sheet below — the layout used
/// on almost every screen of the design.
class SheetLayout extends StatelessWidget {
  final Widget header;
  final Widget body;
  final double headerHeight;
  final Widget? bottom;
  final Alignment headerAlign;

  const SheetLayout({
    super.key,
    required this.header,
    required this.body,
    this.headerHeight = 130,
    this.bottom,
    this.headerAlign = Alignment.bottomLeft,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: W2T.rust,
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: headerHeight + top,
            child: Padding(
              padding: EdgeInsets.fromLTRB(Gap.page, top + 20, Gap.page, 24),
              child: Align(alignment: headerAlign, child: header),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: W2T.butter, borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
              clipBehavior: Clip.antiAlias,
              child: body,
            ),
          ),
        ],
      ),
      // Butter behind the bottom bar, so its rounded corners don't show the rust background.
      bottomNavigationBar: bottom == null ? null : ColoredBox(color: W2T.butter, child: bottom),
    );
  }
}

class CircleBack extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const CircleBack({super.key, this.icon = Icons.arrow_back_rounded, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: W2T.butter,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: 'Back',
        icon: Icon(icon, color: W2T.rustDark),
        onPressed: onTap ?? () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

/// Shows an ingredient photo, or its first two letters when there's no photo.
class IngredientImage extends StatelessWidget {
  final String id;
  final double size;
  const IngredientImage(this.id, {super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    final ing = catalogById[id];
    if (ing?.image != null) {
      return Image.asset(ing!.image!, width: size, height: size, fit: BoxFit.contain);
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: W2T.cream, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        (ing?.name ?? id).substring(0, 2),
        style: TextStyle(fontWeight: FontWeight.w700, color: W2T.rust, fontSize: size * 0.32),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const Tag(this.text, {super.key, this.bg = W2T.oliveSoft, this.fg = const Color(0xFF2F3A16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

/// "Use today" / "Use within 2 days" / "Good for 9 days" / "Pantry".
({String text, bool urgent}) expiryLabel(FridgeItem item) {
  final ing = catalogById[item.ingredientId];
  if (ing?.isPantry ?? false) return (text: 'Pantry', urgent: false);
  final d = item.daysLeft(DateTime.now());
  if (d < 0) return (text: 'Past its date — check it', urgent: true);
  if (d == 0) return (text: 'Use today', urgent: true);
  if (d <= 2) return (text: 'Use within $d day${d == 1 ? '' : 's'}', urgent: true);
  return (text: 'Good for $d days', urgent: false);
}

String ingredientNames(Iterable<String> ids) =>
    ids.map((id) => (catalogById[id]?.name ?? id).toLowerCase()).join(', ');

/// Spacing used everywhere, so every screen lines up the same way.
class Gap {
  static const page = 24.0; // left/right padding of every screen
  static const card = 16.0; // padding inside cards
  static const section = 28.0; // space between sections
}

/// White rounded card with a soft shadow — the only card style in the app.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(Gap.card), this.onTap, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x14321005), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// Section heading with an optional small action on the right.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: heading(18))),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: W2T.rust)),
          ),
      ],
    );
  }
}

/// Friendly message when a list is empty, with an optional button.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? button;
  final VoidCallback? onButton;
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.button, this.onButton});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: W2T.rustTint, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: W2T.rust),
          ),
          const SizedBox(height: 16),
          Text(title, style: heading(17)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: W2T.muted, height: 1.45)),
          if (button != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onButton, child: Text(button!)),
          ],
        ],
      ),
    );
  }
}

/// Big food photo with a soft shadow, as used in the design.
class FoodImage extends StatelessWidget {
  final String asset;
  final double size;
  final double turns;
  const FoodImage(this.asset, {super.key, required this.size, this.turns = 0});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: turns,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x55321005), blurRadius: 24, offset: Offset(0, 14))],
        ),
        child: Image.asset(asset, width: size, height: size, fit: BoxFit.contain),
      ),
    );
  }
}
