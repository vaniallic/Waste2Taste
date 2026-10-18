import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AddIngredientsScreen extends StatefulWidget {
  const AddIngredientsScreen({super.key});

  @override
  State<AddIngredientsScreen> createState() => _AddIngredientsScreenState();
}

class _AddIngredientsScreenState extends State<AddIngredientsScreen> {
  final _selected = <String>{};
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final list = catalog
        .where((i) => (_category == 'All' || i.category == _category) && (q.isEmpty || i.name.toLowerCase().contains(q)))
        .toList();

    return SheetLayout(
      headerHeight: 64,
      header: Row(
        children: [
          const CircleBack(),
          const SizedBox(width: 12),
          Text('Add Ingredients', style: heading(24, color: W2T.butter)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(hintText: 'Search ingredients', prefixIcon: Icon(Icons.search_rounded, color: W2T.rust)),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              children: [
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: c == _category,
                      onSelected: (_) => setState(() => _category = c),
                      showCheckmark: false,
                      selectedColor: W2T.olive,
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      labelStyle: TextStyle(color: c == _category ? W2T.butter : W2T.ink, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No ingredients match.', style: TextStyle(color: W2T.muted)))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final ing = list[i];
                      final on = _selected.contains(ing.id);
                      return Semantics(
                        selected: on,
                        button: true,
                        child: GestureDetector(
                          onTap: () => setState(() => on ? _selected.remove(ing.id) : _selected.add(ing.id)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: on ? W2T.olive : Colors.transparent, width: 2.5),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IngredientImage(ing.id, size: 58),
                                      const SizedBox(height: 4),
                                      Text(ing.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                if (on)
                                  const Positioned(
                                    top: 6,
                                    right: 6,
                                    child: CircleAvatar(radius: 11, backgroundColor: W2T.olive, child: Icon(Icons.check_rounded, size: 14, color: W2T.butter)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottom: Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.paddingOf(context).bottom),
        decoration: const BoxDecoration(color: W2T.olive, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Row(
          children: [
            Text('${_selected.length} selected', style: const TextStyle(color: W2T.butter, fontWeight: FontWeight.w500)),
            const SizedBox(width: 14),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: W2T.rust, foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFF6E7A4C)),
                onPressed: _selected.isEmpty
                    ? null
                    : () {
                        context.read<AppState>().addIngredients(_selected);
                        Navigator.pop(context);
                      },
                child: const Text('Add to My Fridge'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
