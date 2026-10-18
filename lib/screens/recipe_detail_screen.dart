import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/sample_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'cook_mode_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _tab = 1; // 0 cookware, 1 ingredients, 2 instructions

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final r = widget.recipe;
    final match = app.matchFor(r);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: 250 + top,
                  decoration: const BoxDecoration(color: W2T.rust, borderRadius: BorderRadius.vertical(bottom: Radius.circular(36))),
                ),
                Positioned(
                  top: top + 70,
                  left: 0,
                  right: 0,
                  child: Center(child: Container(width: 280, height: 280, decoration: const BoxDecoration(color: W2T.rustSoft, shape: BoxShape.circle))),
                ),
                Positioned(top: top + 50, left: 0, right: 0, child: Center(child: FoodImage(r.image, size: 270, turns: -0.14))),
                Positioned(top: top + 8, left: 16, child: const CircleBack()),
                const SizedBox(height: 360, width: double.infinity),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 140),
            sliver: SliverList.list(
              children: [
                Text(r.name, style: heading(26)),
                const SizedBox(height: 2),
                Text('${r.minutes} minutes · ${r.servings} serving${r.servings > 1 ? 's' : ''} · ${r.tool.label}',
                    style: const TextStyle(color: W2T.rust, fontWeight: FontWeight.w500, fontSize: 13)),
                const SizedBox(height: 10),
                Text(r.description, style: const TextStyle(color: W2T.muted)),
                if (match.savesIds.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: W2T.cream, borderRadius: BorderRadius.circular(14)),
                    child: Text.rich(TextSpan(children: [
                      const TextSpan(text: 'Uses up your '),
                      TextSpan(text: ingredientNames(match.savesIds), style: const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' before it goes bad.'),
                    ])),
                  ),
                ],
                const SizedBox(height: 16),
                Row(children: [
                  for (final (i, label) in ['Cookware', 'Ingredients', 'Instructions'].indexed) ...[
                    _TabPill(label, _tab == i, () => setState(() => _tab = i)),
                    const SizedBox(width: 6),
                  ],
                ]),
                const SizedBox(height: 8),
                ...switch (_tab) {
                  0 => r.cookware.map((c) => _Row(text: c)),
                  1 => r.ingredients.map((ing) {
                      final have = app.inFridge(ing.ingredientId);
                      final name = catalogById[ing.ingredientId]?.name ?? ing.ingredientId;
                      return _Row(
                        text: ing.optional ? '$name (optional)' : name,
                        trailing: have ? ing.amount : (ing.optional ? 'skip it' : 'need ${ing.amount}'),
                        mark: have ? true : false,
                      );
                    }),
                  _ => r.steps.indexed.map((s) => _Row(
                        text: '${s.$1 + 1}   ${s.$2.text}',
                        trailing: s.$2.timerSeconds == null ? '' : '${(s.$2.timerSeconds! / 60).ceil()} min',
                      )),
                },
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.paddingOf(context).bottom),
        decoration: const BoxDecoration(color: W2T.olive, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                app.markCooked(r);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nice! Added to your history.')));
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Mark cooked'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: W2T.ink,
                side: BorderSide.none,
                minimumSize: const Size(0, 52),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: W2T.rust, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CookModeScreen(recipe: r))),
                child: const Text('Start Cooking'),
              ),
            ),
          ],
        ),
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
      color: active ? W2T.rust : Colors.white,
      shape: const StadiumBorder(side: BorderSide(color: W2T.rust, width: 1.5)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Text(label, style: TextStyle(color: active ? Colors.white : W2T.rust, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String text;
  final String trailing;
  final bool? mark; // true = have it, false = missing, null = no mark
  const _Row({required this.text, this.trailing = '', this.mark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: W2T.divider, width: 1.5))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mark != null) ...[
            CircleAvatar(
              radius: 10,
              backgroundColor: mark! ? W2T.olive : W2T.rust,
              child: Icon(mark! ? Icons.check_rounded : Icons.add_rounded, size: 13, color: Colors.white),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4))),
          if (trailing.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(trailing, style: TextStyle(fontSize: 12, color: mark == false ? W2T.rust : W2T.muted)),
            ),
        ],
      ),
    );
  }
}
