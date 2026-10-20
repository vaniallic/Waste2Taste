import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/sample_data.dart';
import '../services/api.dart';
import '../services/photo.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'add_ingredients_screen.dart';

/// Take or pick a photo → the backend asks Gemini what's in it →
/// you tick what's right and add it to your fridge.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Uint8List? _photo;
  bool _loading = false;
  String? _error;
  List<ScannedIngredient> _found = [];
  final Set<String> _picked = {};

  Future<void> _take(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 75);
    if (file == null) return;
    final raw = await file.readAsBytes();
    // Shrink big photos first (the browser doesn't always do it for us).
    final bytes = await shrinkPhoto(raw);
    final mime = identical(bytes, raw) && (file.mimeType?.isNotEmpty ?? false) ? file.mimeType! : 'image/jpeg';
    setState(() {
      _photo = bytes;
      _loading = true;
      _error = null;
      _found = [];
      _picked.clear();
    });
    try {
      final scanned = await Api.scan(bytes, mime: mime);
      final found = await _matchOnline(scanned);
      setState(() {
        _found = found;
        _picked.addAll(found.where((f) => f.known).map((f) => f.id));
      });
    } catch (e) {
      debugPrint('Scan failed: $e');
      final code = e is ScanFailed && e.status != null ? ' (error ${e.status})' : ' (${e.runtimeType})';
      setState(() => _error = e is TooManyRequests
          ? 'You scanned a lot in a short time. Wait a few minutes, or pick from the list.'
          : e is ScanFailed && e.status == 503
              ? 'The scanner is busy right now. Try again in a minute, or pick from the list.'
              : 'Couldn\'t read the photo$code. Try again with better light.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Gemini sees more than our built-in list knows. For everything it spotted
  /// that isn't built in, look it up in the online ingredient list (the same one
  /// the search uses), so "salmon" can be added too. What still isn't found stays
  /// under "Also spotted".
  Future<List<ScannedIngredient>> _matchOnline(List<ScannedIngredient> found) async {
    final result = await Future.wait(found.map((f) async {
      if (f.known) return f;
      try {
        final hits = await Api.searchIngredients(f.name, limit: 8);
        final want = f.name.trim().toLowerCase();
        Ingredient? best;
        for (final h in hits) {
          if (h.name.toLowerCase() == want) {
            best = h;
            break;
          }
        }
        best ??= hits.where((h) => h.name.toLowerCase().startsWith(want)).firstOrNull;
        if (best == null) return f;
        catalogById.putIfAbsent(best.id, () => best!);
        return ScannedIngredient(best.id, best.name, true);
      } catch (_) {
        return f; // lookup failed: leave it under "Also spotted"
      }
    }));
    // The same ingredient can come back twice (say "Salmon" and "Salmon fillet").
    final seen = <String>{};
    return result.where((f) => !f.known || seen.add(f.id)).toList();
  }

  void _addToFridge() {
    context.read<AppState>().addIngredients(_picked);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${_picked.length} to your fridge')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final known = _found.where((f) => f.known).toList();
    final other = _found.where((f) => !f.known).toList();

    return SheetLayout(
      headerHeight: 100,
      header: Row(children: [
        const CircleBack(),
        const SizedBox(width: 12),
        Text('Scan ingredients', style: heading(22, color: W2T.butter)),
      ]),
      bottom: _picked.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Gap.page, 8, Gap.page, 16),
                child: FilledButton(onPressed: _addToFridge, child: Text('Add ${_picked.length} to fridge')),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.page, 28, Gap.page, 32),
        children: [
          // Photo area
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _photo == null
                  ? Container(
                      color: Colors.white,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera_outlined, size: 44, color: W2T.rust),
                          SizedBox(height: 10),
                          Text('Take a photo of your fridge\nor groceries', textAlign: TextAlign.center, style: TextStyle(color: W2T.muted)),
                        ],
                      ),
                    )
                  : Stack(fit: StackFit.expand, children: [
                      Image.memory(_photo!, fit: BoxFit.cover),
                      if (_loading)
                        Container(
                          color: Colors.black38,
                          alignment: Alignment.center,
                          child: const Column(mainAxisSize: MainAxisSize.min, children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 12),
                            Text('Looking for ingredients…', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                    ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _loading ? null : () => _take(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : () => _take(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: W2T.ink,
                  side: BorderSide.none,
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ]),

          if (_error != null) ...[
            const SizedBox(height: 20),
            Text(_error!, style: const TextStyle(color: W2T.danger)),
          ],

          if (!_loading && _photo != null && _error == null && _found.isEmpty) ...[
            const SizedBox(height: 28),
            const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No ingredients found',
              message: 'Try a closer photo with the food clearly visible.',
            ),
          ],

          if (known.isNotEmpty) ...[
            const SizedBox(height: Gap.section),
            const SectionTitle('Found'),
            const SizedBox(height: 4),
            const Text('Untick anything that\'s wrong.', style: TextStyle(fontSize: 13, color: W2T.muted)),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: [
                for (final f in known)
                  CheckboxListTile(
                    value: _picked.contains(f.id),
                    onChanged: (v) => setState(() => v == true ? _picked.add(f.id) : _picked.remove(f.id)),
                    secondary: IngredientImage(f.id, size: 40),
                    title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    activeColor: W2T.olive,
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
              ]),
            ),
          ],

          if (other.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Also spotted: ${other.map((o) => o.name).join(', ')}', style: const TextStyle(fontSize: 13, color: W2T.muted)),
            const SizedBox(height: 4),
            const Text('These aren\'t in our ingredient list yet.', style: TextStyle(fontSize: 12, color: W2T.muted)),
          ],

          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AddIngredientsScreen())),
              child: const Text('Pick from the list instead', style: TextStyle(color: W2T.rust, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
