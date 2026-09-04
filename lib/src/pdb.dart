import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'exceptions.dart';
import 'tags.dart';

enum PDBTYPE { LIST, MAP }

class Pdb {
  final PDBTYPE dataType;
  final List<dynamic> _listData = [];
  final Map<dynamic, dynamic> _mapData = {};

  Pdb({this.dataType = PDBTYPE.LIST});

  int get length => dataType == PDBTYPE.LIST ? _listData.length : _mapData.length;

  bool get isEmpty => length == 0;

  bool get isNotEmpty => length > 0;

  Iterable<dynamic> get keys {
    if (dataType == PDBTYPE.LIST) {
      throw PairOnList('List database does not have keys');
    }
    return _mapData.keys;
  }

  Iterable<dynamic> get values {
    return dataType == PDBTYPE.LIST ? _listData : _mapData.values;
  }

  static Future<Pdb> open(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw DatabaseFileDoesNotExist("File $path doesn't exist");
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw DatabaseBroken('Database file is empty');
    }

    final header = bytes[0];
    final PDBTYPE type;
    if (header == TypeTag.listDatabase) {
      type = PDBTYPE.LIST;
    } else if (header == TypeTag.mapDatabase) {
      type = PDBTYPE.MAP;
    } else {
      throw DatabaseBroken('The Database type is invalid');
    }

    final pdb = Pdb(dataType: type);
    final byteData = ByteData.sublistView(bytes);
    int offset = 1;

    if (type == PDBTYPE.LIST) {
      while (offset < bytes.length) {
        final decoded = _decodeValue(bytes, byteData, offset);
        pdb._listData.add(decoded.value);
        offset = decoded.nextOffset;
      }
    } else {
      while (offset < bytes.length) {
        final decodedKey = _decodeKey(bytes, byteData, offset);
        offset = decodedKey.nextOffset;

        final decodedVal = _decodeValue(bytes, byteData, offset);
        offset = decodedVal.nextOffset;

        pdb._mapData[decodedKey.value] = decodedVal.value;
      }
    }

    return pdb;
  }

  Future<void> save(String path, {bool replace = false}) async {
    final file = File(path);
    if (file.existsSync() && !replace) {
      throw DatabaseFileExist(
        'The $path currentlly exist, Either change the path or use "replace: true"',
      );
    }

    final builder = BytesBuilder();
    builder.addByte(dataType == PDBTYPE.LIST ? TypeTag.listDatabase : TypeTag.mapDatabase);

    if (dataType == PDBTYPE.LIST) {
      for (final item in _listData) {
        _encodeValue(builder, item);
      }
    } else {
      for (final entry in _mapData.entries) {
        _encodeKey(builder, entry.key);
        _encodeValue(builder, entry.value);
      }
    }

    await file.create(recursive: true);
    await file.writeAsBytes(builder.toBytes());
  }

  Future<void> addInt(int value, {dynamic key}) async {
    _validateAndSet(key, value);
  }

  Future<void> addBool(bool value, {dynamic key}) async {
    _validateAndSet(key, value);
  }

  Future<void> addString(String value, {dynamic key}) async {
    _validateAndSet(key, value);
  }

  void _validateAndSet(dynamic key, dynamic value) {
    if (dataType == PDBTYPE.LIST) {
      if (key != null) {
        throw PairOnList('You cannot add Key + Value to a List Database');
      }
      _listData.add(value);
    } else {
      if (key == null) {
        throw SingleValueOnMap('Key should not be null in a Map Database');
      }
      if (key is! int && key is! String) {
        throw KeyTypeInvalid('Key type is invalid');
      }
      _mapData[key] = value;
    }
  }

  dynamic get(dynamic key) {
    if (dataType == PDBTYPE.LIST) {
      throw PairOnList('Cannot access by key in a List Database');
    }
    return _mapData[key];
  }

  dynamic getAt(int index) {
    if (dataType == PDBTYPE.MAP) {
      throw SingleValueOnMap('Cannot access by index in a Map Database');
    }
    return _listData[index];
  }

  dynamic operator [](dynamic keyOrIndex) {
    if (dataType == PDBTYPE.LIST) {
      if (keyOrIndex is! int) {
        throw KeyTypeInvalid('Index must be an integer');
      }
      return _listData[keyOrIndex];
    } else {
      return _mapData[keyOrIndex];
    }
  }

  void operator []=(dynamic keyOrIndex, dynamic value) {
    if (dataType == PDBTYPE.LIST) {
      if (keyOrIndex is! int) {
        throw KeyTypeInvalid('Index must be an integer');
      }
      _listData[keyOrIndex] = value;
    } else {
      if (keyOrIndex is! int && keyOrIndex is! String) {
        throw KeyTypeInvalid('Key type is invalid');
      }
      _mapData[keyOrIndex] = value;
    }
  }

  void set(dynamic key, dynamic value) {
    if (dataType == PDBTYPE.LIST) {
      throw PairOnList('Cannot use set with key in a List Database');
    }
    if (key is! int && key is! String) {
      throw KeyTypeInvalid('Key type is invalid');
    }
    _mapData[key] = value;
  }

  void setAt(int index, dynamic value) {
    if (dataType == PDBTYPE.MAP) {
      throw SingleValueOnMap('Cannot use setAt in a Map Database');
    }
    _listData[index] = value;
  }

  bool containsKey(dynamic key) {
    if (dataType == PDBTYPE.LIST) {
      return false;
    }
    return _mapData.containsKey(key);
  }

  bool contains(dynamic value) {
    if (dataType == PDBTYPE.LIST) {
      return _listData.contains(value);
    }
    return _mapData.containsValue(value);
  }

  dynamic remove(dynamic keyOrValue) {
    if (dataType == PDBTYPE.LIST) {
      return _listData.remove(keyOrValue);
    } else {
      return _mapData.remove(keyOrValue);
    }
  }

  dynamic removeAt(int index) {
    if (dataType == PDBTYPE.MAP) {
      throw SingleValueOnMap('Cannot use removeAt in a Map Database');
    }
    return _listData.removeAt(index);
  }

  void clear() {
    _listData.clear();
    _mapData.clear();
  }

  dynamic all() {
    if (dataType == PDBTYPE.LIST) {
      return List<dynamic>.from(_listData);
    } else {
      return Map<dynamic, dynamic>.from(_mapData);
    }
  }

  List<dynamic> toList() {
    if (dataType == PDBTYPE.MAP) {
      throw SingleValueOnMap('Cannot convert Map database to List directly');
    }
    return List<dynamic>.from(_listData);
  }

  Map<dynamic, dynamic> toMap() {
    if (dataType == PDBTYPE.LIST) {
      throw PairOnList('Cannot convert List database to Map directly');
    }
    return Map<dynamic, dynamic>.from(_mapData);
  }

  static void _encodeKey(BytesBuilder builder, dynamic key) {
    if (key is int) {
      builder.addByte(TypeTag.intKey);
      final data = ByteData(8);
      data.setInt64(0, key);
      builder.add(data.buffer.asUint8List());
    } else if (key is String) {
      builder.addByte(TypeTag.stringKey);
      final encoded = utf8.encode(key);
      final lengthData = ByteData(4);
      lengthData.setUint32(0, encoded.length);
      builder.add(lengthData.buffer.asUint8List());
      builder.add(encoded);
    } else {
      throw KeyTypeInvalid('Key type is invalid: ${key.runtimeType}');
    }
  }

  static void _encodeValue(BytesBuilder builder, dynamic value) {
    if (value == null) {
      builder.addByte(TypeTag.nullValue);
    } else if (value is bool) {
      builder.addByte(value ? TypeTag.booleanTrue : TypeTag.booleanFalse);
    } else if (value is int) {
      builder.addByte(TypeTag.intValue);
      final data = ByteData(8);
      data.setInt64(0, value);
      builder.add(data.buffer.asUint8List());
    } else if (value is String) {
      builder.addByte(TypeTag.stringValue);
      final encoded = utf8.encode(value);
      final lengthData = ByteData(4);
      lengthData.setUint32(0, encoded.length);
      builder.add(lengthData.buffer.asUint8List());
      builder.add(encoded);
    } else {
      throw DatabaseBroken('Unsupported value type: ${value.runtimeType}');
    }
  }

  static _DecodedItem _decodeKey(List<int> bytes, ByteData byteData, int offset) {
    if (offset >= bytes.length) {
      throw DatabaseBroken('Corrupted database while reading key');
    }

    final tag = bytes[offset];
    offset += 1;

    if (tag == TypeTag.intKey) {
      if (offset + 8 > bytes.length) {
        throw DatabaseBroken('Corrupted database reading int key');
      }
      final key = byteData.getInt64(offset);
      return _DecodedItem(key, offset + 8);
    } else if (tag == TypeTag.stringKey) {
      if (offset + 4 > bytes.length) {
        throw DatabaseBroken('Corrupted database reading string key length');
      }
      final len = byteData.getUint32(offset);
      offset += 4;
      if (offset + len > bytes.length) {
        throw DatabaseBroken('Corrupted database reading string key bytes');
      }
      final strBytes = bytes.sublist(offset, offset + len);
      final key = utf8.decode(strBytes);
      return _DecodedItem(key, offset + len);
    } else {
      throw DatabaseBroken('Invalid key tag: $tag');
    }
  }

  static _DecodedItem _decodeValue(List<int> bytes, ByteData byteData, int offset) {
    if (offset >= bytes.length) {
      throw DatabaseBroken('Corrupted database while reading value');
    }

    final tag = bytes[offset];
    offset += 1;

    if (tag == TypeTag.nullValue) {
      return _DecodedItem(null, offset);
    } else if (tag == TypeTag.booleanTrue) {
      return _DecodedItem(true, offset);
    } else if (tag == TypeTag.booleanFalse) {
      return _DecodedItem(false, offset);
    } else if (tag == TypeTag.intValue) {
      if (offset + 8 > bytes.length) {
        throw DatabaseBroken('Corrupted database reading int value');
      }
      final value = byteData.getInt64(offset);
      return _DecodedItem(value, offset + 8);
    } else if (tag == TypeTag.stringValue) {
      if (offset + 4 > bytes.length) {
        throw DatabaseBroken('Corrupted database reading string value length');
      }
      final len = byteData.getUint32(offset);
      offset += 4;
      if (offset + len > bytes.length) {
        throw DatabaseBroken('Corrupted database reading string value bytes');
      }
      final strBytes = bytes.sublist(offset, offset + len);
      final value = utf8.decode(strBytes);
      return _DecodedItem(value, offset + len);
    } else {
      throw DatabaseBroken('Invalid value tag: $tag');
    }
  }
}

class _DecodedItem {
  final dynamic value;
  final int nextOffset;

  _DecodedItem(this.value, this.nextOffset);
}
