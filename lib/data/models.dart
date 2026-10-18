/// An ingredient the app knows about (the catalogue).
class Ingredient {
  final String id;
  final String name;
  final String? image; // asset path, web link (http...), or null to show the initials
  final String category; // Protein, Veggies, Carbs, Sauces, Dairy, Pantry
  final int shelfDays; // rough days it keeps in the fridge after adding

  const Ingredient({required this.id, required this.name, this.image, required this.category, required this.shelfDays});

  bool get isPantry => shelfDays >= 180;

  // Used to save ingredients that came from the online list (see AppState.customIngredients).
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'image': image, 'category': category, 'shelf': shelfDays};

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        id: j['id'] as String,
        name: j['name'] as String,
        image: j['image'] as String?,
        category: j['category'] as String,
        shelfDays: (j['shelf'] as num).toInt(),
      );
}

/// One ingredient sitting in the user's fridge.
class FridgeItem {
  final String ingredientId;
  int qty;
  final DateTime expiresAt;

  FridgeItem({required this.ingredientId, required this.qty, required this.expiresAt});

  int daysLeft(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
    return exp.difference(today).inDays;
  }

  Map<String, dynamic> toJson() => {'id': ingredientId, 'qty': qty, 'exp': expiresAt.toIso8601String()};

  factory FridgeItem.fromJson(Map<String, dynamic> j) =>
      FridgeItem(ingredientId: j['id'] as String, qty: j['qty'] as int, expiresAt: DateTime.parse(j['exp'] as String));
}

class RecipeIngredient {
  final String ingredientId;
  final String amount;
  final bool optional;
  const RecipeIngredient(this.ingredientId, this.amount, {this.optional = false});
}

class RecipeStep {
  final String text;
  final int? timerSeconds;
  const RecipeStep(this.text, {this.timerSeconds});
}

enum Tool { stove, riceCooker, microwave, oven, airFryer, blender, steamer, toaster }

extension ToolLabel on Tool {
  String get label => switch (this) {
        Tool.stove => 'Stove',
        Tool.riceCooker => 'Rice cooker',
        Tool.microwave => 'Microwave',
        Tool.oven => 'Oven',
        Tool.airFryer => 'Air fryer',
        Tool.blender => 'Blender',
        Tool.steamer => 'Steamer',
        Tool.toaster => 'Toaster',
      };
}

class Recipe {
  final String id;
  final String name;
  final String image;
  final String description;
  final int minutes;
  final int servings;
  final Tool tool;
  final List<String> cookware;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final Set<String> tags; // e.g. 'Halal', 'Vegetarian', 'Spicy', 'Pork'

  const Recipe({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.minutes,
    required this.servings,
    required this.tool,
    required this.cookware,
    required this.ingredients,
    required this.steps,
    this.tags = const <String>{},
  });
}

/// A recipe compared against what's in the fridge.
class RecipeMatch {
  final Recipe recipe;
  final List<RecipeIngredient> have;
  final List<RecipeIngredient> missing; // required ones only
  final List<String> savesIds; // ingredients it uses that expire soon

  const RecipeMatch(this.recipe, this.have, this.missing, this.savesIds);

  int get requiredCount => recipe.ingredients.where((i) => !i.optional).length;
  int get haveRequiredCount => have.where((i) => !i.optional).length;
  bool get canCookNow => missing.isEmpty;
}

class CookedEntry {
  final String recipeId;
  final DateTime date;
  final List<String> savedIds;

  const CookedEntry(this.recipeId, this.date, this.savedIds);

  Map<String, dynamic> toJson() => {'r': recipeId, 'd': date.toIso8601String(), 's': savedIds};

  factory CookedEntry.fromJson(Map<String, dynamic> j) =>
      CookedEntry(j['r'] as String, DateTime.parse(j['d'] as String), List<String>.from(j['s'] as List));
}
