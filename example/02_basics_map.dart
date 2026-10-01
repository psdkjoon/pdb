// =============================================================================
// EXAMPLE 2: The absolute basics — a "map" database
// =============================================================================
//
// A MAP database stores values under a "key" (a name you choose), and you
// read them back using that same key — just like a Dart `Map<String, dynamic>`
// or a JSON object with named fields.
//
// Use a MAP when you want to look things up by name, e.g. settings, or a
// single recipe's details (its name, prep time, whether it's vegetarian).
// Use a LIST (example 01) when you just have a bunch of similar items and
// don't need to name each one individually.
//
// Run this file with:
//   dart run example/02_basics_map.dart
// =============================================================================

import 'package:pdb/pdb.dart';

Future<void> main() async {
  // -------------------------------------------------------------------------
  // STEP 1: Create a new, empty MAP database.
  // -------------------------------------------------------------------------
  final db = Pdb(dataType: PDBTYPE.MAP);

  // -------------------------------------------------------------------------
  // STEP 2: Add values, each with a `key` so you can find it again later.
  // -------------------------------------------------------------------------
  // A key can be a String or an int. Pick whatever makes sense — here we
  // use descriptive String keys, like naming fields in a settings file.
  db.addString('Spaghetti Carbonara', key: 'name');
  db.addInt(20, key: 'minutes_to_cook');
  db.addBool(false, key: 'is_vegetarian');

  // -------------------------------------------------------------------------
  // STEP 3: Read values back by their key, not by position.
  // -------------------------------------------------------------------------
  print('Recipe name: ${db.get('name')}');
  // `[]` works exactly like `.get(...)` for a map database:
  print('Minutes to cook: ${db['minutes_to_cook']}');
  print('Is vegetarian: ${db.get('is_vegetarian')}');

  // Trying to read a key that was never set just gives you `null`,
  // same as a normal Dart Map — it does NOT throw an error:
  print('Unknown key: ${db.get('does_not_exist')}');

  // -------------------------------------------------------------------------
  // STEP 4: Check whether a key exists, update it, or remove it.
  // -------------------------------------------------------------------------
  print('Has "name"? ${db.containsKey('name')}');

  // You can overwrite an existing key's value with `set` or `[]=`:
  db.set('name', 'Spaghetti Carbonara (Grandma\'s Recipe)');
  db['minutes_to_cook'] = 25; // same idea, different syntax
  print('Updated name: ${db.get('name')}');
  print('Updated minutes: ${db.get('minutes_to_cook')}');

  // You can also store `null` as a value on purpose — e.g. "we know this
  // recipe has a photo field, but no photo has been added yet":
  db.set('photo_url', null);
  print('photo_url is: ${db.get('photo_url')}');
  // Careful: this makes `containsKey` and "is the value null" two different
  // questions! The key exists, even though its value is null:
  print('containsKey("photo_url") is still: ${db.containsKey('photo_url')}');

  // Remove a key entirely (different from setting it to null — this removes
  // the key itself, so containsKey becomes false):
  db.remove('is_vegetarian');
  print(
    'Has "is_vegetarian" after removing it? '
    '${db.containsKey('is_vegetarian')}',
  );

  // -------------------------------------------------------------------------
  // STEP 5: Save to disk and load it back.
  // -------------------------------------------------------------------------
  await db.save('example_single_recipe.pdb', replace: true);
  final loaded = await Pdb.open('example_single_recipe.pdb');

  print('');
  print('--- Re-loaded from disk ---');
  print('Recipe name: ${loaded.get('name')}');
  print('Minutes to cook: ${loaded.get('minutes_to_cook')}');

  // -------------------------------------------------------------------------
  // STEP 6: See every key and every value, or get a normal Dart Map copy.
  // -------------------------------------------------------------------------
  print('All keys: ${loaded.keys}');
  print('All values: ${loaded.values}');
  print('How many fields stored: ${loaded.length}');
  print('Is it empty? ${loaded.isEmpty}');

  // An independent, normal Dart Map<dynamic, dynamic> copy — changing this
  // copy does NOT change the database itself:
  final asMap = loaded.toMap();
  print('As a normal Dart Map: $asMap');

  // Next: 03_recipe_box.dart puts both LIST and MAP ideas together into a
  // realistic example, and 04_errors_and_edge_cases.dart covers the things
  // that intentionally throw errors, so you know what to expect.
}
