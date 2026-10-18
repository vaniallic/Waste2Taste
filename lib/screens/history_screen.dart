import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'recipe_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _when(DateTime d) {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (days == 0) return 'Today, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return SheetLayout(
      headerHeight: 120,
      header: Align(alignment: Alignment.bottomLeft, child: Text('History', style: heading(28, color: W2T.butter))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.page, 28, Gap.page, 120),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(color: W2T.olive, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Expanded(child: _Stat('${app.history.length}', 'meals cooked')),
              Expanded(child: _Stat('${app.totalSaved}', 'ingredients saved from the bin')),
            ]),
          ),
          const SizedBox(height: Gap.section),
          if (app.history.isNotEmpty) ...[const SectionTitle('Recent'), const SizedBox(height: 12)],
          if (app.history.isEmpty)
            const EmptyState(
              icon: Icons.history_rounded,
              title: 'No meals yet',
              message: 'Cook a recipe and tap "Mark cooked" — it will show up here with the ingredients you saved.',
            )
          else
            for (final h in app.history)
              if (recipesById[h.recipeId] case final r?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r))),
                      child: SizedBox(
                        height: 76,
                        child: Row(children: [
                          const SizedBox(width: 6),
                          FoodImage(r.image, size: 64),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text(_when(h.date), style: const TextStyle(fontSize: 11, color: W2T.muted)),
                                if (h.savedIds.isNotEmpty)
                                  Text('Saved: ${ingredientNames(h.savedIds)}', style: const TextStyle(fontSize: 11, color: W2T.olive, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: Text('Cook again', style: TextStyle(color: W2T.rust, fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: heading(30, color: W2T.butter)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, height: 1.35, color: W2T.oliveSoft)),
      ]),
    );
  }
}
