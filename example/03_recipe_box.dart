// =============================================================================
// EXAMPLE 3: A realistic use case — a small "recipe box" app
// =============================================================================
//
// This shows a more complete, practical setup: a LIST database holding your
// recipe names, plus a separate MAP database per recipe holding its details
// (cook time, whether it's vegetarian, etc). This mirrors a very common
// real-world pattern: an "index" of items, and separate per-item records.
//
// Why split it like this instead of one giant database? `pdb`'s databases
// don't support nested structures (a list of maps, or a map whose values
// are themselves maps) — each database is either a flat list OR a flat
// key->value map. Splitting "the list of names" from "each recipe's own
// details file" is the simplest way to model that with what `pdb` offers
// today, and it also means you only load the full details of a recipe when
// you actually need them.
//
// Run this file with:
//   dart run example/03_recipe_box.dart
// =============================================================================

import 'dart:io';

import 'package:pdb/pdb.dart';

const _indexFile = 'recipe_index.pdb';

Future<void> main() async {
  // -------------------------------------------------------------------------
  // STEP 1: Set up the "index" — a LIST database of recipe names. This is
  // what you'd show in e.g. a menu or search list in your app.
  // -------------------------------------------------------------------------
  final index = await _openOrCreateList(_indexFile);

  if (index.isEmpty) {
    print('No recipes yet — adding two starter recipes.');
    await _addRecipe(
      index,
      name: 'Spaghetti Carbonara',
      minutesToCook: 20,
      isVegetarian: false,
    );
    await _addRecipe(
      index,
      name: 'Veggie Stir Fry',
      minutesToCook: 15,
      isVegetarian: true,
    );
  } else {
    print('Found an existing recipe box with ${index.length} recipe(s).');
  }

  // -------------------------------------------------------------------------
  // STEP 2: List every recipe name from the index.
  // -------------------------------------------------------------------------
  print('');
  print('--- All recipes ---');
  for (var i = 0; i < index.length; i++) {
    print('${i + 1}. ${index[i]}');
  }

  // -------------------------------------------------------------------------
  // STEP 3: Open one specific recipe's details file, by name.
  // -------------------------------------------------------------------------
  // Each recipe's details live in their own small MAP database, named after
  // the recipe itself. This is the "only load what you need" idea: we don't
  // have to open every recipe's details just to show the list above.
  const chosenRecipe = 'Spaghetti Carbonara';
  final details = await Pdb.open(_detailsFileFor(chosenRecipe));

  print('');
  print('--- Details for "$chosenRecipe" ---');
  print('Cook time: ${details.get('minutes_to_cook')} minutes');
  print('Vegetarian: ${details.get('is_vegetarian')}');

  // -------------------------------------------------------------------------
  // STEP 4: Add a brand new recipe, the way your app would when a user
  // fills out a form.
  // -------------------------------------------------------------------------
  const newRecipeName = 'Lemon Garlic Salmon';
  if (!index.contains(newRecipeName)) {
    await _addRecipe(
      index,
      name: newRecipeName,
      minutesToCook: 25,
      isVegetarian: false,
    );
    print('');
    print(
      'Added "$newRecipeName". Recipe box now has ${index.length} '
      'recipe(s).',
    );
  }
}

// -----------------------------------------------------------------------
// Helper: opens the recipe index if it already exists on disk, or creates
// a brand-new empty one if this is the very first run.
//
// This "open if it exists, otherwise create" pattern is extremely common —
// almost every app using pdb for persistent storage will want some version
// of this at startup.
// -----------------------------------------------------------------------
Future<Pdb> _openOrCreateList(String path) async {
  if (File(path).existsSync()) {
    return Pdb.open(path);
  }
  return Pdb(dataType: PDBTYPE.LIST);
}

// -----------------------------------------------------------------------
// Helper: adds a recipe to the index AND writes its own details file, then
// saves the (updated) index back to disk. Keeping both writes inside one
// function makes sure we never end up with a name in the index that has no
// matching details file, or vice versa.
// -----------------------------------------------------------------------
Future<void> _addRecipe(
  Pdb index, {
  required String name,
  required int minutesToCook,
  required bool isVegetarian,
}) async {
  // Add the name to the index (in-memory only so far — addString is sync).
  index.addString(name);

  // Create that recipe's own details database.
  final details = Pdb(dataType: PDBTYPE.MAP);
  details.addString(name, key: 'name');
  details.addInt(minutesToCook, key: 'minutes_to_cook');
  details.addBool(isVegetarian, key: 'is_vegetarian');
  await details.save(_detailsFileFor(name), replace: true);

  // Now persist the updated index to disk too. `replace: true` is needed
  // here because, after the very first run, this file will already exist.
  await index.save(_indexFile, replace: true);
}

// -----------------------------------------------------------------------
// Helper: turns a recipe name into a safe-ish file name for its details
// database. Real code should sanitize this further (e.g. strip slashes),
// this is simplified for the example.
// -----------------------------------------------------------------------
String _detailsFileFor(String recipeName) {
  final safeName = recipeName.toLowerCase().replaceAll(' ', '_');
  return 'recipe_details_$safeName.pdb';
}
