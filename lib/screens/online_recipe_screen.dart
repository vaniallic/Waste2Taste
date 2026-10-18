import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Detail page for a recipe that comes from TheMealDB (via our backend).
class OnlineRecipeScreen extends StatefulWidget {
  final OnlineRecipe recipe;
  const OnlineRecipeScreen({super.key, required this.recipe});

  @override
  State<OnlineRecipeScreen> createState() => _OnlineRecipeScreenState();
}

class _OnlineRecipeScreenState extends State<OnlineRecipeScreen> {
  int _tab = 0; // 0 ingredients, 1 steps

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final top = MediaQuery.paddingOf(context).top;
    final meta = [r.area, r.category].whereType<String>().join(' · ');

    return Scaffold(
      backgroundColor: W2T.butter,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.1,
                child: Image.network(
                  r.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: W2T.rust),
                ),
              ),
              Positioned(top: top + 8, left: Gap.page, child: const CircleBack()),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.page, 24, Gap.page, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: heading(24)),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(meta, style: const TextStyle(color: W2T.rust, fontWeight: FontWeight.w500, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                Tag('You have ${r.matches} of ${r.ingredients.length} ingredients'),
                const SizedBox(height: 20),
                Row(children: [
                  _Pill('Ingredients', _tab == 0, () => setState(() => _tab = 0)),
                  const SizedBox(width: 8),
                  _Pill('Steps', _tab == 1, () => setState(() => _tab = 1)),
                ]),
                const SizedBox(height: 8),
                if (_tab == 0)
                  for (final i in r.ingredients)
                    _Line(
                      leading: CircleAvatar(
                        radius: 10,
                        backgroundColor: i.have ? W2T.olive : W2T.rust,
                        child: Icon(i.have ? Icons.check_rounded : Icons.add_rounded, size: 13, color: Colors.white),
                      ),
                      text: i.name,
                      trailing: i.measure,
                    )
                else
                  for (final (n, s) in r.steps.indexed)
                    _Line(
                      leading: Text('${n + 1}', style: const TextStyle(color: W2T.rust, fontWeight: FontWeight.w700)),
                      text: s,
                    ),
                const SizedBox(height: 16),
                const Text('Recipe from TheMealDB', style: TextStyle(fontSize: 12, color: W2T.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Pill(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? W2T.rust : Colors.white,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(label, style: TextStyle(color: active ? Colors.white : W2T.rust, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final Widget leading;
  final String text;
  final String trailing;
  const _Line({required this.leading, required this.text, this.trailing = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: W2T.divider))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 28, child: Padding(padding: const EdgeInsets.only(top: 1), child: leading)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.45))),
          if (trailing.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(trailing, style: const TextStyle(fontSize: 12, color: W2T.muted)),
            ),
        ],
      ),
    );
  }
}
