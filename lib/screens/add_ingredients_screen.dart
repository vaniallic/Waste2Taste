import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/sample_data.dart';
import '../services/api.dart';
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

  // The whole online list (TheMealDB), loaded once when the screen opens.
  // Searching and the category chips just filter it, so no request per key.
  List<Ingredient> _online = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await Api.searchIngredients('', limit: 1000);
      // Register them so the tiles (and the fridge later) know their name and photo.
      for (final i in all) {
        catalogById.putIfAbsent(i.id, () => i);
      }
      if (mounted) setState(() => _online = all);
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn\'t load more ingredients. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final q = _query.trim().toLowerCase();
    bool matches(Ingredient i) =>
        (_category == 'All' || i.category == _category) && (q.isEmpty || i.name.toLowerCase().contains(q));

    final local = catalog.where(matches).toList();
    final localIds = catalog.map((i) => i.id).toSet();
    final online = _online.where((i) => !localIds.contains(i.id) && matches(i)).toList();

    return SheetLayout(
      headerHeight: 100,
      header: Row(
        children: [
          const CircleBack(),
          const SizedBox(width: 12),
          Text('Add ingredients', style: heading(22, color: W2T.butter)),
        ],
      ),
      // Slivers build the tiles lazily, so 500+ photos don't all load at once.
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Gap.page, 24, Gap.page, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(hintText: 'Search ingredients', prefixIcon: Icon(Icons.search_rounded, color: W2T.rust)),
                  ),
                  const SizedBox(height: 16),

                  // Categories wrap onto two lines instead of being cut off.
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in categories)
                        ChoiceChip(
                          label: Text(c),
                          selected: c == _category,
                          onSelected: (_) => setState(() => _category = c),
                          showCheckmark: false,
                          selectedColor: W2T.olive,
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: const StadiumBorder(),
                          labelStyle: TextStyle(color: c == _category ? W2T.butter : W2T.ink, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.section),
                ],
              ),
            ),
          ),

          if (local.isNotEmpty) _grid(local, app),

          const SliverPadding(
            padding: EdgeInsets.fromLTRB(Gap.page, Gap.section, Gap.page, 12),
            sliver: SliverToBoxAdapter(child: SectionTitle('More ingredients')),
          ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: W2T.rust)),
              ),
            )
          else if (_error != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.page),
              sliver: SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_error!, style: const TextStyle(color: W2T.danger)),
                  TextButton(onPressed: _retry, child: const Text('Try again', style: TextStyle(color: W2T.rust, fontWeight: FontWeight.w600))),
                ]),
              ),
            )
          else if (online.isNotEmpty)
            _grid(online, app)
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.page),
              sliver: SliverToBoxAdapter(
                child: local.isEmpty
                    ? const EmptyState(icon: Icons.search_off_rounded, title: 'No match', message: 'Try another name or category.')
                    : const Text('Nothing else found.', style: TextStyle(color: W2T.muted)),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottom: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.page, 12, Gap.page, 12),
          child: FilledButton(
            onPressed: _selected.isEmpty
                ? null
                : () {
                    context.read<AppState>().addIngredients(_selected);
                    Navigator.pop(context);
                  },
            child: Text(_selected.isEmpty ? 'Select ingredients' : 'Add ${_selected.length} to my fridge'),
          ),
        ),
      ),
    );
  }

  Widget _grid(List<Ingredient> items, AppState app) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.page),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) {
            final ing = items[i];
            final on = _selected.contains(ing.id);
            return _IngredientTile(
              id: ing.id,
              name: ing.name,
              selected: on,
              inFridge: app.inFridge(ing.id),
              onTap: () => setState(() => on ? _selected.remove(ing.id) : _selected.add(ing.id)),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final String id;
  final String name;
  final bool selected;
  final bool inFridge;
  final VoidCallback onTap;
  const _IngredientTile({required this.id, required this.name, required this.selected, required this.inFridge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? W2T.olive : Colors.transparent, width: 2),
            boxShadow: const [BoxShadow(color: Color(0x14321005), blurRadius: 12, offset: Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: W2T.cream, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: IngredientImage(id, size: 56),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(inFridge ? 'In fridge' : ' ', style: const TextStyle(fontSize: 11, color: W2T.muted)),
                ],
              ),
              if (selected)
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
  }
}
