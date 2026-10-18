import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'add_ingredients_screen.dart';
import 'home_shell.dart';
import 'recipe_detail_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.fridgeSorted;
    final pick = app.tonightPick;
    final readyCount = app.matches().where((m) => m.canCookNow).length;

    return SheetLayout(
      headerHeight: 120,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Hi, ${app.userName ?? 'there'}', style: const TextStyle(color: Color(0xFFF8E7C2), fontSize: 14)),
          const SizedBox(height: 2),
          Text("What's in your fridge?", style: heading(24, color: W2T.butter)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.page, 24, Gap.page, 120),
        children: [
          // Quick actions
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_rounded,
                  title: 'Add',
                  subtitle: 'Pick from list',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddIngredientsScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.photo_camera_outlined,
                  title: 'Scan',
                  subtitle: 'Use camera',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
                ),
              ),
            ],
          ),

          // Tonight's pick
          if (pick != null) ...[
            const SizedBox(height: Gap.section),
            const SectionTitle('Cook tonight'),
            const SizedBox(height: 12),
            _TonightCard(
              name: pick.recipe.name,
              image: pick.recipe.image,
              minutes: pick.recipe.minutes,
              saves: pick.savesIds.isEmpty ? null : ingredientNames(pick.savesIds),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: pick.recipe))),
            ),
          ],

          // Fridge
          const SizedBox(height: Gap.section),
          SectionTitle('My fridge · ${items.length}',
              action: items.isEmpty ? null : 'See recipes', onAction: () => HomeShell.of(context)?.goTo(1)),
          const SizedBox(height: 4),
          if (items.isNotEmpty)
            const Text('Items that spoil first are on top.', style: TextStyle(fontSize: 13, color: W2T.muted)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            EmptyState(
              icon: Icons.kitchen_outlined,
              title: 'Your fridge is empty',
              message: 'Add what you have and we\'ll find recipes you can cook right now.',
              button: 'Add ingredients',
              onButton: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddIngredientsScreen())),
            )
          else
            for (final item in items)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: _FridgeRow(id: item.ingredientId)),

          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => HomeShell.of(context)?.goTo(1),
              child: Text(readyCount == 0 ? 'Find recipes' : 'Find recipes · $readyCount ready'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: W2T.rust, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: W2T.butter, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: W2T.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TonightCard extends StatelessWidget {
  final String name;
  final String image;
  final int minutes;
  final String? saves;
  final VoidCallback onTap;
  const _TonightCard({required this.name, required this.image, required this.minutes, required this.saves, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: W2T.olive,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(Gap.card, Gap.card, 8, Gap.card),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: heading(20, color: W2T.butter)),
                const SizedBox(height: 4),
                Text('$minutes min', style: const TextStyle(fontSize: 13, color: W2T.oliveSoft)),
                if (saves != null) ...[
                  const SizedBox(height: 10),
                  Tag('Uses your $saves', bg: W2T.butter, fg: W2T.olive),
                ],
              ],
            ),
          ),
          FoodImage(image, size: 104),
        ],
      ),
    );
  }
}

class _FridgeRow extends StatelessWidget {
  final String id;
  const _FridgeRow({required this.id});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final item = app.fridge.where((f) => f.ingredientId == id).firstOrNull;
    if (item == null) return const SizedBox.shrink();
    final label = expiryLabel(item);
    final ing = catalogById[id];

    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(color: W2T.rust, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => app.removeIngredient(id),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: W2T.cream, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: IngredientImage(id, size: 40),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ing?.name ?? id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(label.text,
                      style: TextStyle(fontSize: 12, color: label.urgent ? W2T.danger : W2T.muted, fontWeight: label.urgent ? FontWeight.w600 : FontWeight.w400)),
                ],
              ),
            ),
            _Stepper(
              qty: item.qty,
              onMinus: () => item.qty == 1 ? _confirmRemove(context, app, id) : app.changeQty(id, -1),
              onPlus: () => app.changeQty(id, 1),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, AppState app, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: W2T.butter,
        title: Text('Remove ${catalogById[id]?.name ?? id}?', style: heading(20)),
        content: const Text('It will be taken out of your fridge list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: W2T.ink))),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44), backgroundColor: W2T.rust, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) app.removeIngredient(id);
  }
}

/// Compact − qty + control in one pill.
class _Stepper extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _Stepper({required this.qty, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: W2T.cream, borderRadius: BorderRadius.circular(22)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_rounded, size: 18, color: W2T.rust), tooltip: 'Less'),
          SizedBox(width: 20, child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(onPressed: onPlus, icon: const Icon(Icons.add_rounded, size: 18, color: W2T.rust), tooltip: 'More'),
        ],
      ),
    );
  }
}
