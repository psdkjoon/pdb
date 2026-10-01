// =============================================================================
// EXAMPLE 1: The absolute basics — a "list" database
// =============================================================================
//
// `pdb` can store your data in two shapes:
//   1. A LIST  -> just a bunch of values, one after another, read back by
//                 their position (index), like a normal Dart `List`.
//   2. A MAP   -> values stored under a "key" (a name), read back by that
//                 name, like a normal Dart `Map`. See example 02 for this.
//
// This file shows the LIST version, since it's the simpler of the two.
// We'll use it to store a plain list of recipe names.
//
// Run this file with:
//   dart run example/01_basics_list.dart
// =============================================================================

import 'package:pdb/pdb.dart';

Future<void> main() async {
  // -------------------------------------------------------------------------
  // STEP 1: Create a new, empty database in memory.
  // -------------------------------------------------------------------------
  // Nothing is saved to disk yet — this just creates an empty container.
  // `dataType: PDBTYPE.LIST` tells it "I want to store a list of values".
  final db = Pdb(dataType: PDBTYPE.LIST);

  // -------------------------------------------------------------------------
  // STEP 2: Add some values.
  // -------------------------------------------------------------------------
  // There's a separate method for each type of value you can store:
  //   db.addString(...)  for text
  //   db.addInt(...)     for whole numbers
  //   db.addBool(...)    for true/false
  //
  // These are instant — they just add the value to an in-memory list, no
  // disk access happens here, so you don't need to `await` them. (More on
  // why that matters in example 04.)
  db.addString('Spaghetti Carbonara');
  db.addString('Chicken Tikka Masala');
  db.addInt(2); // could represent e.g. "this recipe takes 2 hours"
  db.addBool(true); // could represent e.g. "is this recipe vegetarian?"

  // -------------------------------------------------------------------------
  // STEP 3: Read values back by their position (index), starting at 0.
  // -------------------------------------------------------------------------
  print('First item: ${db[0]}'); // same as db.getAt(0)
  print('Second item: ${db.getAt(1)}');
  print('How many items are stored: ${db.length}');

  // isEmpty / isNotEmpty are handy for a quick check without comparing
  // `.length` to 0 yourself:
  print('Is the database empty? ${db.isEmpty}');
  print('Does it have anything in it? ${db.isNotEmpty}');

  // -------------------------------------------------------------------------
  // STEP 4: Save it to a file on disk.
  // -------------------------------------------------------------------------
  // `save` DOES touch the disk, so it's `async` and you must `await` it.
  // `replace: true` means "overwrite the file if it already exists" — useful
  // while you're experimenting. Without it, saving to a path that already
  // exists throws an error instead of silently overwriting your data — see
  // example 04 for exactly what that looks like and why it's a safety net.
  await db.save('example_recipes.pdb', replace: true);
  print('Saved to example_recipes.pdb!');

  // -------------------------------------------------------------------------
  // STEP 5: Load it back from disk (e.g. in a totally different run of your
  // program — this is what you'll do every time your app starts up).
  // -------------------------------------------------------------------------
  // `open` also touches the disk, so it's `async` too.
  final loadedDb = await Pdb.open('example_recipes.pdb');

  print('');
  print('--- Re-loaded from disk ---');
  print('First item: ${loadedDb[0]}');
  print('Total items: ${loadedDb.length}');

  // -------------------------------------------------------------------------
  // A few other handy things you can do with a list database:
  // -------------------------------------------------------------------------

  // Change a value at a specific position:
  loadedDb.setAt(0, 'Spaghetti Carbonara (my version)');
  print('After setAt(0, ...): ${loadedDb[0]}');

  // Check if a value exists anywhere in the list:
  print(
    'Contains "Chicken Tikka Masala": '
    '${loadedDb.contains('Chicken Tikka Masala')}',
  );

  // Remove a value by its position (this also shifts later items down by
  // one, exactly like Dart's own List.removeAt):
  loadedDb.removeAt(1);
  print('After removeAt(1), length is now: ${loadedDb.length}');

  // Get an independent, normal Dart List<dynamic> copy of everything.
  // "Independent" means changing this copy does NOT change the database —
  // it's a snapshot, not a live view.
  final everything = loadedDb.toList();
  print('As a normal Dart list: $everything');

  // `all()` does the same thing as `toList()` for a list database — the
  // only difference is `all()` also works on a MAP database (where it
  // returns a Map instead). Use `toList()`/`toMap()` when you want Dart's
  // type system to double-check you're using the right database shape;
  // use `all()` when you're writing code that should work with either.
  print('Same thing via all(): ${loadedDb.all()}');

  // Wipe everything (works the same on both LIST and MAP databases):
  loadedDb.clear();
  print('After clear(), length is: ${loadedDb.length}');

  // Next: see 02_basics_map.dart for the key -> value style of database,
  // 03_recipe_box.dart for a realistic combined example, and
  // 04_errors_and_edge_cases.dart for things that can go wrong (and why
  // that's a good thing).
}
