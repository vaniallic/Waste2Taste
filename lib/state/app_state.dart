import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';
import '../data/sample_data.dart';

/// All app data lives here. Screens read it with `context.watch<AppState>()`
/// and change it by calling the methods below. Everything is saved on the
/// phone with shared_preferences, so it survives closing the app.
class AppState extends ChangeNotifier {
  bool loaded = false;
  bool seenOnboarding = false;
  String? userName;
  Uint8List? photo; // profile picture, saved separately because it's big
  List<FridgeItem> fridge = [];
  List<CookedEntry> history = [];
  Set<String> diet = {'Halal'};
  Set<Tool> tools = {Tool.stove, Tool.riceCooker};

  static const _key = 'w2t_state_v1';
  static const _photoKey = 'w2t_photo_v1';

  // ---------- load & save ----------

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final photoRaw = prefs.getString(_photoKey);
    if (photoRaw != null) photo = base64Decode(photoRaw);
    if (raw != null) {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      seenOnboarding = j['seen'] as bool? ?? false;
      userName = j['name'] as String?;
      fridge = (j['fridge'] as List).map((e) => FridgeItem.fromJson(e as Map<String, dynamic>)).toList();
      history = (j['history'] as List).map((e) => CookedEntry.fromJson(e as Map<String, dynamic>)).toList();
      diet = Set<String>.from(j['diet'] as List);
      tools = (j['tools'] as List).map((t) => Tool.values.byName(t as String)).toSet();
    } else {
      _seedDemoFridge();
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'seen': seenOnboarding,
        'name': userName,
        'fridge': fridge.map((f) => f.toJson()).toList(),
        'history': history.map((h) => h.toJson()).toList(),
        'diet': diet.toList(),
        'tools': tools.map((t) => t.name).toList(),
      }),
    );
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  /// A few items so the app isn't empty the first time it opens.
  void _seedDemoFridge() {
    final now = DateTime.now();
    fridge = [
      FridgeItem(ingredientId: 'tomato', qty: 2, expiresAt: now.add(const Duration(days: 2))),
      FridgeItem(ingredientId: 'rice', qty: 1, expiresAt: now),
      FridgeItem(ingredientId: 'egg', qty: 3, expiresAt: now.add(const Duration(days: 9))),
      FridgeItem(ingredientId: 'chicken', qty: 1, expiresAt: now.add(const Duration(days: 2))),
      FridgeItem(ingredientId: 'soy_sauce', qty: 1, expiresAt: now.add(const Duration(days: 365))),
      FridgeItem(ingredientId: 'garlic', qty: 1, expiresAt: now.add(const Duration(days: 20))),
    ];
  }

  // ---------- account ----------

  void finishOnboarding() {
    seenOnboarding = true;
    _changed();
  }

  void signIn(String name) {
    userName = name.trim().isEmpty ? 'Friend' : name.trim();
    _changed();
  }

  void updateProfile({required String name, Uint8List? newPhoto}) {
    userName = name.trim().isEmpty ? 'Friend' : name.trim();
    photo = newPhoto;
    _changed();
    _savePhoto();
  }

  Future<void> _savePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    if (photo == null) {
      await prefs.remove(_photoKey);
    } else {
      await prefs.setString(_photoKey, base64Encode(photo!));
    }
  }

  void signOut() {
    userName = null;
    _changed();
  }

  // ---------- fridge ----------

  /// Fridge sorted so the items that spoil first are on top.
  List<FridgeItem> get fridgeSorted => [...fridge]..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));

  bool inFridge(String id) => fridge.any((f) => f.ingredientId == id);

  void addIngredients(Iterable<String> ids) {
    final now = DateTime.now();
    for (final id in ids) {
      final existing = fridge.where((f) => f.ingredientId == id);
      if (existing.isNotEmpty) {
        existing.first.qty++;
      } else {
        final days = catalogById[id]?.shelfDays ?? 5;
        fridge.add(FridgeItem(ingredientId: id, qty: 1, expiresAt: now.add(Duration(days: days))));
      }
    }
    _changed();
  }

  void changeQty(String id, int delta) {
    final item = fridge.firstWhere((f) => f.ingredientId == id);
    item.qty += delta;
    if (item.qty <= 0) fridge.remove(item);
    _changed();
  }

  void removeIngredient(String id) {
    fridge.removeWhere((f) => f.ingredientId == id);
    _changed();
  }

  /// Ingredient ids that go bad within [days] days.
  Set<String> expiringSoon({int days = 2}) {
    final now = DateTime.now();
    return fridge.where((f) => !(catalogById[f.ingredientId]?.isPantry ?? false) && f.daysLeft(now) <= days).map((f) => f.ingredientId).toSet();
  }

  // ---------- recipes ----------

  bool _fitsDiet(Recipe r) {
    if (diet.contains('Halal') && r.tags.contains('Pork')) return false;
    if (diet.contains('Vegetarian') && !r.tags.contains('Vegetarian')) return false;
    return true;
  }

  /// Every recipe compared with the fridge, best matches first.
  List<RecipeMatch> matches({bool onlyMyTools = false}) {
    final soon = expiringSoon();
    final list = <RecipeMatch>[];
    for (final r in recipes) {
      if (!_fitsDiet(r)) continue;
      if (onlyMyTools && !tools.contains(r.tool)) continue;
      final have = r.ingredients.where((i) => inFridge(i.ingredientId)).toList();
      final missing = r.ingredients.where((i) => !i.optional && !inFridge(i.ingredientId)).toList();
      final saves = have.map((i) => i.ingredientId).where(soon.contains).toList();
      list.add(RecipeMatch(r, have, missing, saves));
    }
    list.sort((a, b) {
      final m = a.missing.length.compareTo(b.missing.length);
      if (m != 0) return m;
      return b.savesIds.length.compareTo(a.savesIds.length);
    });
    return list;
  }

  RecipeMatch matchFor(Recipe r) => matches().firstWhere((m) => m.recipe.id == r.id,
      orElse: () => RecipeMatch(r, const [], r.ingredients.where((i) => !i.optional).toList(), const []));

  /// The single best thing to cook tonight: can cook now and saves the most.
  RecipeMatch? get tonightPick {
    final ready = matches().where((m) => m.canCookNow).toList();
    if (ready.isEmpty) return null;
    ready.sort((a, b) => b.savesIds.length.compareTo(a.savesIds.length));
    return ready.first;
  }

  /// Marks a recipe as cooked: takes one of each used ingredient out of the
  /// fridge (pantry items stay) and adds it to history.
  void markCooked(Recipe r) {
    final soon = expiringSoon();
    final saved = <String>[];
    for (final ing in r.ingredients) {
      if (!inFridge(ing.ingredientId)) continue;
      if (soon.contains(ing.ingredientId)) saved.add(ing.ingredientId);
      if (catalogById[ing.ingredientId]?.isPantry ?? false) continue;
      final item = fridge.firstWhere((f) => f.ingredientId == ing.ingredientId);
      item.qty--;
      if (item.qty <= 0) fridge.remove(item);
    }
    history.insert(0, CookedEntry(r.id, DateTime.now(), saved));
    _changed();
  }

  int get totalSaved => history.fold(0, (sum, h) => sum + h.savedIds.length);

  // ---------- preferences ----------

  void toggleDiet(String d) {
    diet.contains(d) ? diet.remove(d) : diet.add(d);
    _changed();
  }

  void toggleTool(Tool t) {
    tools.contains(t) ? tools.remove(t) : tools.add(t);
    _changed();
  }
}
