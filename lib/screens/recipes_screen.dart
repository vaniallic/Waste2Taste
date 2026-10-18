import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  int _tab = 0; // 0 = cook now, 1 = missing 1–2
  bool _myTools = false;
  bool _quick = false;

  static const _tints = [Color(0xFFF2C9A0), Color(0xFFE8B4A0), Color(0xFFD9C58A), Color(0xFFC9D3A8)];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    var all = app.matches(onlyMyTools: _myTools);
    if (_quick) all = all.where((m) => m.recipe.minutes <= 20).toList();
    final now = all.where((m) => m.canCookNow).toList();
    final almost = all.where((m) => m.missing.isNotEmpty && m.missing.length <= 2).toList();
    final list = _tab == 0 ? now : almost;

    return SheetLayout(
      headerHeight: 96,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Based on your ${app.fridge.length} ingredients', style: const TextStyle(color: Color(0xFFF8E7C2), fontSize: 13)),
          Text('Recipes for you', style: heading(26, color: W2T.butter)),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _TabPill('Cook now · ${now.length}', _tab == 0, () => setState(() => _tab = 0)),
                    const SizedBox(width: 8),
                    _TabPill('Missing 1–2 · ${almost.length}', _tab == 1, () => setState(() => _tab = 1)),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, children: [
                    _Filter('My kitchen tools', _myTools, () => setState(() => _myTools = !_myTools)),
                    _Filter('Under 20 min', _quick, () => setState(() => _quick = !_quick)),
                  ]),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _tab == 0 ? 'Nothing you can cook right now.\nCheck "Missing 1–2" or add more ingredients.' : 'No close matches yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: W2T.muted),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 44, 20, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 44,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 190,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _RecipeCard(match: list[i], tint: _tints[i % _tints.length], turns: i.isEven ? -0.1 : 0.08),
                  childCount: list.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabPill(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? W2T.rust : Colors.transparent,
      shape: const StadiumBorder(side: BorderSide(color: W2T.rust, width: 1.5)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(label, style: TextStyle(color: active ? Colors.white : W2T.rust, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
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

class _RecipeCard extends StatelessWidget {
  final RecipeMatch match;
  final Color tint;
  final double turns;
  const _RecipeCard({required this.match, required this.tint, required this.turns});

  @override
  Widget build(BuildContext context) {
    final r = match.recipe;
    final ready = match.canCookNow;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r))),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 70, color: tint),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 30, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.25)),
                      const SizedBox(height: 3),
                      Text('${r.minutes} min · ${r.tool.label}', style: const TextStyle(fontSize: 11, color: W2T.muted)),
                      const SizedBox(height: 6),
                      ready
                          ? Tag('You have ${match.haveRequiredCount}/${match.requiredCount}')
                          : Tag('Missing: ${ingredientNames(match.missing.map((m) => m.ingredientId))}', bg: W2T.rustTint, fg: const Color(0xFF8A2A12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            child: Center(child: FoodImage(r.image, size: 128, turns: turns)),
          ),
        ],
      ),
    );
  }
}
