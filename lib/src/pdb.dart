import 'dart:io';

import 'tags.dart';
import 'exceptions.dart';

enum PDBTYPE { LIST, MAP }

class Pdb {
  List<int> _bytes;
  PDBTYPE dataType;

  Pdb({this.dataType = PDBTYPE.LIST})
      : _bytes = [
          dataType == PDBTYPE.LIST ? TypeTag.listDatabase : TypeTag.mapDatabase,
        ];

  static Future<Pdb> open(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      List<int> bytes = await file.readAsBytes();
      Pdb pdb = Pdb(
        dataType: bytes.first == TypeTag.listDatabase
            ? PDBTYPE.LIST
            : bytes.first == TypeTag.mapDatabase
                ? PDBTYPE.MAP
                : throw DatabaseBroken('The Database type is invalid'),
      );
      pdb._bytes = bytes;
      return pdb;
    } else
      throw DatabaseFileDoesNotExist('File $path doesn\'t exist');
  }

  Future<void> save(String path, {bool replace = false}) async {
    final file = File(path);
    if (file.existsSync() && !replace)
      throw DatabaseFileExist(
        'The $path currentlly exist, Either change the path or use \"replace: true\"',
      );
    else
      await file.create();
    await file.writeAsBytes(_bytes);
  }

  Future<void> addInt(int value, {dynamic key = null}) async {
    if (dataType == PDBTYPE.LIST) {
      if (key != null)
        throw PairOnList('You cannot add Key + Value to a List Database');
      _bytes.add(TypeTag.intValue);
      _bytes.add(value);
      return;
    }
    if (dataType == PDBTYPE.MAP && key == null)
      throw SingleValueOnMap('Key should not be null in a Map Database');
    if (key is int) {
      _bytes.add(TypeTag.intKey);
      _bytes.add(key);
    } else if (key is String) {
      _bytes.add(TypeTag.stringKey);
      _bytes.add(key.length);
      _bytes = _bytes + key.codeUnits;
    } else {
      throw KeyTypeInvalid('Key type is invalid');
    }
    _bytes.add(TypeTag.intValue);
    _bytes.add(value);
  }

  Future<void> addBool(bool value, {dynamic key = null}) async {
    if (dataType == PDBTYPE.LIST) {
      if (key != null)
        throw PairOnList('You cannot add Key + Value to a List Database');
      _bytes.add(value ? TypeTag.booleanTrue : TypeTag.booleanFalse);
      return;
    }
    if (dataType == PDBTYPE.MAP && key == null)
      throw SingleValueOnMap('Key should not be null in a Map Database');
    if (key is int) {
      _bytes.add(TypeTag.intKey);
      _bytes.add(key);
    } else if (key is String) {
      _bytes.add(TypeTag.stringKey);
      _bytes.add(key.length);
      _bytes = _bytes + key.codeUnits;
    } else {
      throw KeyTypeInvalid('Key type is invalid');
    }
    _bytes.add(value ? TypeTag.booleanTrue : TypeTag.booleanFalse);
  }

  Future<void> addString(String value, {dynamic key = null}) async {
    if (dataType == PDBTYPE.LIST) {
      if (key != null)
        throw PairOnList('You cannot add Key + Value to a List Database');
      _bytes.add(TypeTag.stringValue);
      _bytes.add(value.length);
      _bytes = _bytes + value.codeUnits;
      return;
    }
    if (dataType == PDBTYPE.MAP && key == null)
      throw SingleValueOnMap('Key should not be null in a Map Database');
    if (key is int) {
      _bytes.add(TypeTag.intKey);
      _bytes.add(key);
    } else if (key is String) {
      _bytes.add(TypeTag.stringKey);
      _bytes.add(key.length);
      _bytes = _bytes + key.codeUnits;
    } else {
      throw KeyTypeInvalid('Key type is invalid');
    }
    _bytes.add(TypeTag.stringValue);
    _bytes.add(value.length);
    _bytes = _bytes + value.codeUnits;
  }

  // List<Map<String, dynamic>> all() {}
}
