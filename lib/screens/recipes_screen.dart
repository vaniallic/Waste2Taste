import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../services/api.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'add_ingredients_screen.dart';
import 'online_recipe_screen.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  int _tab = 0; // 0 = cook now, 1 = missing 1–2, 2 = online
  Future<List<OnlineRecipe>>? _online;
  String _onlineKey = '';

  /// Loads online recipes once per fridge content (not on every rebuild).
  Future<List<OnlineRecipe>> _onlineFor(Iterable<String> ids) {
    final key = (ids.toList()..sort()).join(',');
    if (_online == null || key != _onlineKey) {
      _onlineKey = key;
      _online = Api.recipesFor(ids);
    }
    return _online!;
  }
  bool _myTools = false;
  bool _quick = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    var all = app.matches(onlyMyTools: _myTools);
    if (_quick) all = all.where((m) => m.recipe.minutes <= 20).toList();
    final now = all.where((m) => m.canCookNow).toList();
    final almost = all.where((m) => m.missing.isNotEmpty && m.missing.length <= 2).toList();
    final list = _tab == 0 ? now : almost;

    return SheetLayout(
      headerHeight: 120,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('From your ${app.fridge.length} ingredients', style: const TextStyle(color: Color(0xFFF8E7C2), fontSize: 14)),
          const SizedBox(height: 2),
          Text('Recipes for you', style: heading(24, color: W2T.butter)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.page, 24, Gap.page, 120),
        children: [
          // Segmented tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(child: _Segment('Cook now (${now.length})', _tab == 0, () => setState(() => _tab = 0))),
                Expanded(child: _Segment('Almost (${almost.length})', _tab == 1, () => setState(() => _tab = 1))),
                Expanded(child: _Segment('Online', _tab == 2, () => setState(() => _tab = 2))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_tab != 2) Wrap(spacing: 8, runSpacing: 8, children: [
            _Filter('My kitchen tools', _myTools, () => setState(() => _myTools = !_myTools)),
            _Filter('Under 20 min', _quick, () => setState(() => _quick = !_quick)),
          ]),
          const SizedBox(height: 20),

          if (_tab == 2)
            FutureBuilder<List<OnlineRecipe>>(
              future: _onlineFor(app.fridge.map((f) => f.ingredientId)),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: CircularProgressIndicator(color: W2T.rust)),
                  );
                }
                if (snap.hasError) {
                  return EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Couldn\'t load recipes',
                    message: 'Check your internet connection and try again.',
                    button: 'Try again',
                    onButton: () => setState(() => _online = null),
                  );
                }
                final online = snap.data ?? [];
                if (online.isEmpty) {
                  return const EmptyState(
                    icon: Icons.public_rounded,
                    title: 'No online recipes yet',
                    message: 'Add a few more ingredients to your fridge.',
                  );
                }
                return Column(children: [
                  for (final r in online) Padding(padding: const EdgeInsets.only(bottom: 12), child: _OnlineCard(recipe: r)),
                ]);
              },
            )
          else if (list.isEmpty)
            _tab == 0
                ? EmptyState(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Nothing ready to cook yet',
                    message: almost.isEmpty
                        ? 'Add a few more ingredients and recipes will show up here.'
                        : 'You\'re close! ${almost.length} recipe${almost.length == 1 ? ' needs' : 's need'} just 1–2 more ingredients.',
                    button: almost.isEmpty ? 'Add ingredients' : 'See what\'s missing',
                    onButton: almost.isEmpty
                        ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddIngredientsScreen()))
                        : () => setState(() => _tab = 1),
                  )
                : const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No close matches',
                    message: 'Try turning off the filters, or add more ingredients.',
                  )
          else
            for (final m in list)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: _RecipeCard(match: m)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Segment(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: active ? W2T.rust : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: TextStyle(color: active ? Colors.white : W2T.ink, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Filter(this.label, this.on, this.onTap);

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: W2T.olive,
      backgroundColor: Colors.white,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(color: on ? W2T.butter : W2T.ink, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

/// Horizontal recipe card: text on the left, dish photo on the right.
class _RecipeCard extends StatelessWidget {
  final RecipeMatch match;
  const _RecipeCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final r = match.recipe;
    final ready = match.canCookNow;
    return AppCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r))),
      padding: const EdgeInsets.fromLTRB(Gap.card, Gap.card, 8, Gap.card),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: heading(17)),
                const SizedBox(height: 4),
                Text('${r.minutes} min · ${r.tool.label}', style: const TextStyle(fontSize: 12, color: W2T.muted)),
                const SizedBox(height: 10),
                ready
                    ? Tag('You have ${match.haveRequiredCount}/${match.requiredCount}')
                    : Tag('Missing: ${ingredientNames(match.missing.map((m) => m.ingredientId))}', bg: W2T.rustTint, fg: const Color(0xFF8A2A12)),
                if (match.savesIds.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Uses your ${ingredientNames(match.savesIds)}', style: const TextStyle(fontSize: 12, color: W2T.olive, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(color: W2T.cream, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Image.asset(r.image, width: 92, height: 92, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}

class _OnlineCard extends StatelessWidget {
  final OnlineRecipe recipe;
  const _OnlineCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    return AppCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OnlineRecipeScreen(recipe: r))),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              r.image,
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 84, height: 84, color: W2T.cream),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: heading(16), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text([r.area, r.category].whereType<String>().join(' · '), style: const TextStyle(fontSize: 12, color: W2T.muted)),
                const SizedBox(height: 8),
                Tag('You have ${r.matches}/${r.ingredients.length}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
