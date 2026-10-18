import 'dart:async';

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

  // More ingredients from the online list, searched while you type.
  Timer? _debounce;
  List<Ingredient> _remote = [];
  bool _searching = false;
  String? _remoteError;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String v) {
    setState(() => _query = v);
    _debounce?.cancel();
    final q = v.trim();
    if (q.length < 2) {
      setState(() {
        _remote = [];
        _searching = false;
        _remoteError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() {
      _searching = true;
      _remoteError = null;
    });
    try {
      final found = await Api.searchIngredients(q);
      if (!mounted || q != _query.trim()) return;
      // Register them so the tiles can show their name and photo.
      for (final i in found) {
        catalogById.putIfAbsent(i.id, () => i);
      }
      setState(() => _remote = found);
    } catch (_) {
      if (mounted && q == _query.trim()) setState(() => _remoteError = 'Couldn\'t load more ingredients. Check your connection.');
    } finally {
      if (mounted && q == _query.trim()) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final q = _query.trim().toLowerCase();
    final list = catalog
        .where((i) => (_category == 'All' || i.category == _category) && (q.isEmpty || i.name.toLowerCase().contains(q)))
        .toList();
    final localIds = catalog.map((i) => i.id).toSet();
    final online = _remote.where((i) => !localIds.contains(i.id) && (_category == 'All' || i.category == _category)).toList();
    final searchedOnline = q.length >= 2;

    return SheetLayout(
      headerHeight: 100,
      header: Row(
        children: [
          const CircleBack(),
          const SizedBox(width: 12),
          Text('Add ingredients', style: heading(22, color: W2T.butter)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.page, 24, Gap.page, 24),
        children: [
          TextField(
            onChanged: _onQuery,
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

          if (list.isNotEmpty)
            _grid(list, app)
          else if (!searchedOnline || (!_searching && online.isEmpty))
            const EmptyState(icon: Icons.search_off_rounded, title: 'No match', message: 'Try another name or category.'),

          // Online ingredients (TheMealDB)
          if (searchedOnline) ...[
            const SizedBox(height: Gap.section),
            const SectionTitle('More ingredients'),
            const SizedBox(height: 12),
            if (_searching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: W2T.rust)),
              )
            else if (_remoteError != null)
              Text(_remoteError!, style: const TextStyle(color: W2T.danger))
            else if (online.isEmpty)
              const Text('Nothing else found online.', style: TextStyle(color: W2T.muted))
            else
              _grid(online, app),
          ] else if (_query.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: Gap.section),
              child: Text('Can\'t find it? Type a name to search hundreds more ingredients online.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: W2T.muted)),
            ),
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
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
