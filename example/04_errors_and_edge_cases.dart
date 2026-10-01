// =============================================================================
// EXAMPLE 4: Errors and edge cases — what can go wrong, and why that's good
// =============================================================================
//
// `pdb` throws specific, named exceptions instead of generic errors, so you
// can `catch` exactly the mistake you're worried about and handle it
// sensibly (e.g. show the user a friendly message) instead of crashing.
//
// This file deliberately triggers every single exception type `pdb` can
// throw, one at a time, so you know exactly what causes each one and what
// the error looks like. None of these are bugs — they're `pdb` protecting
// you from mixing up the two database shapes (LIST vs MAP) or from
// accidentally destroying data.
//
// Run this file with:
//   dart run example/04_errors_and_edge_cases.dart
// =============================================================================

import 'dart:io';

import 'package:pdb/pdb.dart';

Future<void> main() async {
  // -------------------------------------------------------------------------
  // 1) PairOnList — "you tried to use a key on a LIST database"
  // -------------------------------------------------------------------------
  // LIST databases don't have named keys — only positions (0, 1, 2, ...).
  // Passing a `key:` to `add*` on a LIST database doesn't make sense, so it
  // throws instead of silently ignoring your key.
  print('--- 1) PairOnList ---');
  final listDb = Pdb(dataType: PDBTYPE.LIST);
  try {
    listDb.addString('oops', key: 'this is not allowed on a list');
  } on PairOnList catch (e) {
    print('Caught PairOnList, as expected: $e');
  }

  // The same exception also fires if you try to read `.keys` from a list
  // database, or call `.get(...)` / `.set(...)` on one:
  try {
    // ignore: unused_local_variable
    final k = listDb.keys;
  } on PairOnList catch (e) {
    print('Caught PairOnList from .keys too: $e');
  }

  // -------------------------------------------------------------------------
  // 2) SingleValueOnMap — "you tried to use a MAP database like a LIST"
  // -------------------------------------------------------------------------
  // The opposite problem: MAP databases are addressed by key, not position,
  // so adding a value with no key, or using list-only methods, doesn't make
  // sense for them.
  print('');
  print('--- 2) SingleValueOnMap ---');
  final mapDb = Pdb(dataType: PDBTYPE.MAP);
  try {
    mapDb.addString('oops'); // no key given!
  } on SingleValueOnMap catch (e) {
    print('Caught SingleValueOnMap, as expected: $e');
  }

  // Same exception fires for list-only operations on a map database, like
  // `getAt`, `setAt`, `removeAt`, or `toList()`:
  try {
    mapDb.getAt(0);
  } on SingleValueOnMap catch (e) {
    print('Caught SingleValueOnMap from getAt too: $e');
  }

  // -------------------------------------------------------------------------
  // 3) KeyTypeInvalid — "that key (or index) isn't the right type"
  // -------------------------------------------------------------------------
  // Keys must be a String or an int — nothing else. Likewise, an index into
  // a LIST database must be an int.
  print('');
  print('--- 3) KeyTypeInvalid ---');
  final mapDb2 = Pdb(dataType: PDBTYPE.MAP);
  try {
    // A List or a double, for example, isn't a valid key type:
    mapDb2.set([1, 2, 3], 'value');
  } on KeyTypeInvalid catch (e) {
    print('Caught KeyTypeInvalid, as expected: $e');
  }

  final listDb2 = Pdb(dataType: PDBTYPE.LIST);
  listDb2.addString('first item');
  try {
    // Using a String where a numeric index is required:
    // ignore: unused_local_variable
    final item = listDb2['not a number'];
  } on KeyTypeInvalid catch (e) {
    print('Caught KeyTypeInvalid from a bad index too: $e');
  }

  // -------------------------------------------------------------------------
  // 4) DatabaseFileDoesNotExist — "you tried to open a file that isn't there"
  // -------------------------------------------------------------------------
  print('');
  print('--- 4) DatabaseFileDoesNotExist ---');
  try {
    await Pdb.open('this_file_was_never_created.pdb');
  } on DatabaseFileDoesNotExist catch (e) {
    print('Caught DatabaseFileDoesNotExist, as expected: $e');
  }

  // -------------------------------------------------------------------------
  // 5) DatabaseFileExist — "you tried to save over a file without permission"
  // -------------------------------------------------------------------------
  // This is a safety net: saving to a path that already has a file at it
  // will refuse to overwrite it UNLESS you explicitly say `replace: true`.
  // This stops you from accidentally wiping out a database with one typo.
  print('');
  print('--- 5) DatabaseFileExist ---');
  final db = Pdb(dataType: PDBTYPE.LIST);
  db.addString('some data');
  await db.save('example_protected.pdb', replace: true); // first save, fine

  try {
    // Second save, WITHOUT replace: true -> this is the mistake we're
    // demonstrating. In real code, forgetting `replace: true` here is
    // usually *good* — it means you probably meant to update the existing
    // database using Pdb.open(...) first, not create a new one from scratch.
    await db.save('example_protected.pdb'); // replace defaults to false
  } on DatabaseFileExist catch (e) {
    print('Caught DatabaseFileExist, as expected: $e');
  }

  // The fix is either `replace: true` (if you really do want to overwrite):
  await db.save('example_protected.pdb', replace: true);
  print('Saved successfully with replace: true.');

  // ...or, more commonly, load the existing file, change it, and save it
  // back to the SAME path with replace: true (since the file now exists):
  final existing = await Pdb.open('example_protected.pdb');
  existing.addString('more data');
  await existing.save('example_protected.pdb', replace: true);
  print('Updated the existing database instead of replacing it blindly.');

  // -------------------------------------------------------------------------
  // 6) DatabaseBroken — "the file isn't a valid pdb database"
  // -------------------------------------------------------------------------
  // This fires if the file is empty, has a corrupted/truncated byte
  // sequence, or simply isn't a `.pdb` file at all (e.g. you pointed it at
  // a text file by mistake). We simulate that here by writing garbage bytes
  // to a file and trying to open it.
  print('');
  print('--- 6) DatabaseBroken ---');
  final garbageFile = await _writeGarbageFile('example_garbage.pdb');
  try {
    await Pdb.open(garbageFile);
  } on DatabaseBroken catch (e) {
    print('Caught DatabaseBroken, as expected: $e');
  }

  print('');
  print('All six exception types demonstrated successfully.');
}

// -----------------------------------------------------------------------
// Helper: writes a file containing bytes that don't form a valid database,
// so we can safely demonstrate DatabaseBroken without needing a real
// corrupted file lying around.
// -----------------------------------------------------------------------
Future<String> _writeGarbageFile(String path) async {
  final file = File(path);
  // 0xFF is not a valid "type tag" byte for either a LIST or MAP database,
  // so Pdb.open correctly recognizes this as not-a-real-database and
  // throws DatabaseBroken instead of crashing in some more confusing way.
  await file.writeAsBytes([0xFF, 0x00, 0x01]);
  return path;
}
