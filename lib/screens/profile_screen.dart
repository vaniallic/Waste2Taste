import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _diets = ['Halal', 'Vegetarian', 'No seafood', 'No peanut', 'Lactose free', 'Not spicy'];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final name = app.userName ?? 'Friend';

    return SheetLayout(
      headerHeight: 130,
      header: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: W2T.butter,
            child: Text(name[0].toUpperCase(), style: heading(28, color: W2T.rust)),
          ),
          const SizedBox(height: 8),
          Text('Hi, $name!', style: heading(20, color: W2T.butter)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
        children: [
          Text('Food preferences', style: heading(16)),
          const SizedBox(height: 4),
          const Text('Recipes are filtered with these.', style: TextStyle(fontSize: 12, color: W2T.muted)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final d in _diets) _Chip(d, app.diet.contains(d), () => app.toggleDiet(d)),
          ]),
          const SizedBox(height: 18),
          Text('My kitchen tools', style: heading(16)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final t in Tool.values) _Chip(t.label, app.tools.contains(t), () => app.toggleTool(t)),
          ]),
          const SizedBox(height: 14),
          const _MenuRow(Icons.notifications_none_rounded, 'Expiry reminders'),
          const _MenuRow(Icons.language_rounded, 'Language'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded, color: W2T.rust),
            title: const Text('Log out', style: TextStyle(color: W2T.rust, fontWeight: FontWeight.w600)),
            onTap: app.signOut,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Chip(this.label, this.on, this.onTap);

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

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: W2T.divider, width: 1.5))),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: W2T.olive),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right_rounded, color: W2T.muted),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon'))),
      ),
    );
  }
}
