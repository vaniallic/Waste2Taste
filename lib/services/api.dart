import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../data/models.dart';
import '../data/sample_data.dart';

/// Our small backend on Vercel (see the backend/ folder).
const apiBase = 'https://waste2taste-backend.vercel.app';

class OnlineIngredient {
  final String name;
  final String measure;
  final bool have;
  OnlineIngredient(this.name, this.measure, this.have);
}

class OnlineRecipe {
  final String id;
  final String name;
  final String image;
  final String? category;
  final String? area;
  final int matches;
  final int missing;
  final List<OnlineIngredient> ingredients;
  final List<String> steps;
  final String? youtube;

  OnlineRecipe.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String,
        image = j['image'] as String,
        category = j['category'] as String?,
        area = j['area'] as String?,
        matches = (j['matches'] as num?)?.toInt() ?? 0,
        missing = (j['missing'] as num?)?.toInt() ?? 0,
        ingredients = [
          for (final i in (j['ingredients'] as List? ?? []))
            OnlineIngredient(i['name'] as String, (i['measure'] as String?) ?? '', i['have'] == true),
        ],
        steps = [for (final s in (j['steps'] as List? ?? [])) s as String],
        youtube = j['youtube'] as String?;
}

class ScannedIngredient {
  final String id;
  final String name;
  final bool known; // true = it's in our ingredient list and can be added
  ScannedIngredient(this.id, this.name, this.known);
}

/// The backend said we're sending too many requests (HTTP 429).
class TooManyRequests implements Exception {}

class Api {
  /// Recipes from TheMealDB that use the ingredients in your fridge.
  static Future<List<OnlineRecipe>> recipesFor(Iterable<String> ingredientIds) async {
    final names = ingredientIds
        .map((id) => catalogById[id]?.name.toLowerCase())
        .whereType<String>()
        .where((n) => n != 'mixed veggies' && n != 'spam' && n != 'tempe' && n != 'salt')
        .toList();
    if (names.isEmpty) return [];

    final uri = Uri.parse('$apiBase/api/recipes').replace(queryParameters: {'ingredients': names.join(',')});
    final res = await http.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('Recipes failed (${res.statusCode})');
    final list = (jsonDecode(res.body)['recipes'] as List? ?? []);
    return list.map((e) => OnlineRecipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Searches the online ingredient list (TheMealDB, 500+ items with photos).
  static Future<List<Ingredient>> searchIngredients(String query) async {
    final uri = Uri.parse('$apiBase/api/ingredients').replace(queryParameters: {'q': query});
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Ingredients failed (${res.statusCode})');
    final list = (jsonDecode(res.body)['ingredients'] as List? ?? []);
    return [
      for (final e in list)
        Ingredient(
          id: e['id'] as String,
          name: e['name'] as String,
          image: e['image'] as String?,
          category: (e['category'] as String?) ?? 'Pantry',
          shelfDays: (e['shelfDays'] as num?)?.toInt() ?? 7,
        ),
    ];
  }

  /// Sends a photo to the backend, which asks Gemini what ingredients are in it.
  static Future<List<ScannedIngredient>> scan(Uint8List bytes, {String mime = 'image/jpeg'}) async {
    final res = await http
        .post(
          Uri.parse('$apiBase/api/scan'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'image': base64Encode(bytes), 'mime': mime}),
        )
        .timeout(const Duration(seconds: 40));
    if (res.statusCode == 429) throw TooManyRequests();
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw Exception(body['error'] ?? 'Scan failed');
    return [
      for (final i in (body['ingredients'] as List? ?? []))
        ScannedIngredient(i['id'] as String, i['name'] as String, i['known'] == true),
    ];
  }
}
