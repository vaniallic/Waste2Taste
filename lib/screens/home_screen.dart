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
      headerHeight: 96,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Hi, ${app.userName ?? 'there'}!', style: const TextStyle(color: Color(0xFFF8E7C2), fontSize: 13)),
          Text("What's in your fridge?", style: heading(24, color: W2T.butter)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Add Ingredients',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddIngredientsScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  icon: Icons.document_scanner_outlined,
                  label: 'Scan Ingredients',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
                ),
              ),
            ],
          ),
          if (pick != null) ...[
            const SizedBox(height: 16),
            _TonightCard(
              name: pick.recipe.name,
              image: pick.recipe.image,
              subtitle: pick.savesIds.isEmpty ? '${pick.recipe.minutes} min · you have everything' : 'Saves your ${ingredientNames(pick.savesIds)}',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: pick.recipe))),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text('My Fridge', style: heading(20))),
              const Text('Use the red ones first', style: TextStyle(fontSize: 12, color: W2T.brownText)),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const _EmptyFridge()
          else
            for (final item in items) _FridgeRow(id: item.ingredientId),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => HomeShell.of(context)?.goTo(1),
              child: Text('Find recipes · $readyCount ready'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: W2T.rust,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: W2T.butter, size: 22),
              const SizedBox(width: 8),
              Flexible(child: Text(label, style: const TextStyle(color: W2T.butter, fontWeight: FontWeight.w600, fontSize: 14))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TonightCard extends StatelessWidget {
  final String name;
  final String image;
  final String subtitle;
  final VoidCallback onTap;
  const _TonightCard({required this.name, required this.image, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: W2T.olive,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 84,
          child: Row(
            children: [
              Transform.translate(offset: const Offset(-10, 0), child: FoodImage(image, size: 96, turns: -0.17)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('COOK TONIGHT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE9B48F), letterSpacing: .5)),
                    Text(name, style: heading(17, color: W2T.butter)),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: W2T.oliveSoft)),
                  ],
                ),
              ),
              const Padding(padding: EdgeInsets.only(right: 14), child: Icon(Icons.chevron_right_rounded, color: W2T.butter)),
            ],
          ),
        ),
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(color: W2T.rust, borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => app.removeIngredient(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 64,
        padding: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            IngredientImage(id, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ing?.name ?? id, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(label.text,
                      style: TextStyle(fontSize: 11, color: label.urgent ? W2T.danger : W2T.muted, fontWeight: label.urgent ? FontWeight.w600 : FontWeight.w400)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Less ${ing?.name}',
              onPressed: () => item.qty == 1 ? _confirmRemove(context, app, id) : app.changeQty(id, -1),
              icon: const Icon(Icons.remove_rounded, color: W2T.rust),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 28),
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: W2T.butter, borderRadius: BorderRadius.circular(8)),
              child: Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            IconButton(tooltip: 'More ${ing?.name}', onPressed: () => app.changeQty(id, 1), icon: const Icon(Icons.add_rounded, color: W2T.rust)),
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

class _EmptyFridge extends StatelessWidget {
  const _EmptyFridge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: W2T.cream, borderRadius: BorderRadius.circular(20)),
      child: const Column(
        children: [
          Icon(Icons.kitchen_outlined, size: 40, color: W2T.rust),
          SizedBox(height: 8),
          Text('Your fridge is empty', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          SizedBox(height: 4),
          Text('Add or scan what you have to get recipe ideas.', textAlign: TextAlign.center, style: TextStyle(color: W2T.muted)),
        ],
      ),
    );
  }
}
