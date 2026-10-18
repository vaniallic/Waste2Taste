import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../services/notifications.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _diets = ['Halal', 'Vegetarian', 'No seafood', 'No peanut', 'Lactose free', 'Not spicy'];

  void _editProfile(BuildContext context) {
    final app = context.read<AppState>();
    final controller = TextEditingController(text: app.userName ?? '');
    Uint8List? photo = app.photo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: W2T.butter,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) {
          Future<void> pick() async {
            final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 400, imageQuality: 80);
            if (file == null) return;
            final bytes = await file.readAsBytes();
            setSheet(() => photo = bytes);
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(Gap.page, 28, Gap.page, 24 + MediaQuery.viewInsetsOf(sheet).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit profile', style: heading(22)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    GestureDetector(
                      onTap: pick,
                      child: Stack(
                        children: [
                          _Avatar(name: controller.text.isEmpty ? '?' : controller.text, photo: photo, radius: 40, bg: Colors.white),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: W2T.rust, shape: BoxShape.circle, border: Border.all(color: W2T.butter, width: 2)),
                              child: const Icon(Icons.photo_camera_outlined, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: pick,
                          style: TextButton.styleFrom(foregroundColor: W2T.rust, padding: EdgeInsets.zero),
                          child: Text(photo == null ? 'Add photo' : 'Change photo', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        if (photo != null)
                          TextButton(
                            onPressed: () => setSheet(() => photo = null),
                            style: TextButton.styleFrom(foregroundColor: W2T.muted, padding: EdgeInsets.zero),
                            child: const Text('Remove photo'),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: W2T.ink)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setSheet(() {}),
                  decoration: const InputDecoration(hintText: 'Your name', prefixIcon: Icon(Icons.person_outline_rounded, color: W2T.rust)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      sheet.read<AppState>().updateProfile(name: controller.text, newPhoto: photo);
                      Navigator.pop(sheet);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final name = app.userName ?? 'Friend';

    return SheetLayout(
      headerHeight: 150,
      headerAlign: Alignment.centerLeft,
      header: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _editProfile(context),
            child: _Avatar(name: name, photo: app.photo, radius: 34, bg: W2T.butter),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: heading(24, color: W2T.butter), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${app.history.length} meals cooked', style: const TextStyle(color: Color(0xFFF8E7C2), fontSize: 13)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _editProfile(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: W2T.butter,
              side: const BorderSide(color: W2T.butter, width: 1.5),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 38),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.page, 32, Gap.page, 140),
        children: [
          const SectionTitle('Food preferences'),
          const SizedBox(height: 6),
          const Text('Recipes are filtered with these.', style: TextStyle(fontSize: 13, color: W2T.muted)),
          const SizedBox(height: 16),
          AppCard(child: Wrap(spacing: 8, runSpacing: 10, children: [
            for (final d in _diets) _Chip(d, app.diet.contains(d), () => app.toggleDiet(d)),
          ])),

          const SizedBox(height: 40),
          const SectionTitle('My kitchen tools'),
          const SizedBox(height: 6),
          const Text('Only show recipes you can make with these.', style: TextStyle(fontSize: 13, color: W2T.muted)),
          const SizedBox(height: 16),
          AppCard(child: Wrap(spacing: 8, runSpacing: 10, children: [
            for (final t in Tool.values) _Chip(t.label, app.tools.contains(t), () => app.toggleTool(t)),
          ])),

          const SizedBox(height: 40),
          const SectionTitle('Settings'),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                _MenuRow(Icons.person_outline_rounded, 'Edit profile', onTap: () => _editProfile(context)),
                const Divider(height: 1, indent: 60, endIndent: 16, color: Color(0xFFEFE3C8)),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                  secondary: const Icon(Icons.notifications_none_rounded, color: W2T.olive),
                  title: const Text('Expiry reminders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: W2T.ink)),
                  subtitle: const Text('A heads-up the day before something goes bad', style: TextStyle(fontSize: 12, color: W2T.muted)),
                  value: app.reminders,
                  activeTrackColor: W2T.olive,
                  onChanged: (on) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await app.setReminders(on);
                    if (on && !ok) {
                      messenger.showSnackBar(SnackBar(
                        content: Text(Reminders.supported
                            ? 'Notifications are off for Waste2Taste. Turn them on in your phone settings.'
                            : 'Reminders work in the phone app, not in the browser.'),
                      ));
                    }
                  },
                ),
                // Only while developing: sends a notification right now.
                if (kDebugMode) ...[
                  const Divider(height: 1, indent: 60, endIndent: 16, color: Color(0xFFEFE3C8)),
                  _MenuRow(Icons.bolt_rounded, 'Send test reminder', onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await Reminders.sendTest();
                    messenger.showSnackBar(SnackBar(content: Text(ok ? 'Sent. Check your notifications.' : 'Couldn\'t send (no permission, or on the web).')));
                  }),
                ],
                const Divider(height: 1, indent: 60, endIndent: 16, color: Color(0xFFEFE3C8)),
                const _MenuRow(Icons.language_rounded, 'Language'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _MenuRow(Icons.logout_rounded, 'Log out', danger: true, onTap: app.signOut),
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
      backgroundColor: W2T.cream,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      labelStyle: TextStyle(color: on ? W2T.butter : W2T.ink, fontSize: 13, fontWeight: FontWeight.w600),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback? onTap;
  const _MenuRow(this.icon, this.label, {this.danger = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = danger ? W2T.rust : W2T.ink;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Icon(icon, color: danger ? W2T.rust : W2T.olive),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: color)),
      trailing: danger ? null : const Icon(Icons.chevron_right_rounded, color: W2T.muted),
      onTap: onTap ?? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon'))),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final Uint8List? photo;
  final double radius;
  final Color bg;
  const _Avatar({required this.name, required this.photo, required this.radius, required this.bg});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      backgroundImage: photo == null ? null : MemoryImage(photo!),
      child: photo == null ? Text(name[0].toUpperCase(), style: heading(radius * 0.75, color: W2T.rust)) : null,
    );
  }
}
