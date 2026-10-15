import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'exceptions.dart';
import 'tags.dart';
import 'varint.dart';

enum PDBTYPE { LIST, MAP }

class Pdb {
  final PDBTYPE dataType;
  final List<dynamic> _listData;
  final Map<dynamic, dynamic> _mapData;

  Pdb({this.dataType = PDBTYPE.LIST, int? expectedSize})
      : _listData = <dynamic>[],
        _mapData = <dynamic, dynamic>{} {
    if (expectedSize != null && expectedSize < 0) {
      throw ArgumentError('expectedSize must be non-negative');
    }
    if (dataType == PDBTYPE.LIST && expectedSize != null && expectedSize > 0) {
      _listData.length = expectedSize;
      _listData.length = 0;
    }
  }

  int get length =>
      dataType == PDBTYPE.LIST ? _listData.length : _mapData.length;

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

  
static Future<Pdb> open(
    String path, {
    bool create = false,
    PDBTYPE type = PDBTYPE.LIST,
  }) async {
    final file = File(path);
    if (!file.existsSync()) {
      if (create) {
        final pdb = Pdb(dataType: type);
        await pdb.save(path);
        return pdb;
      } else {
        throw DatabaseFileDoesNotExist("File $path doesn't exist");
      }
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw DatabaseBroken('Database file is empty');
    }

    final header = bytes[0];
    final PDBTYPE detectedType;
    if (header == TypeTag.listDatabase) {
      detectedType = PDBTYPE.LIST;
    } else if (header == TypeTag.mapDatabase) {
      detectedType = PDBTYPE.MAP;
    } else {
      throw DatabaseBroken('The Database type is invalid');
    }

    final bool isV2 = bytes.length > 1 && bytes[1] == TypeTag.formatVersion2;

    final pdb = isV2 ? await _openV2(bytes, detectedType) : _openV1(bytes, detectedType);

    return pdb;
  }

  static Pdb _openV1(Uint8List bytes, PDBTYPE type) {
    final pdb = Pdb(dataType: type);
    final byteData = ByteData.sublistView(bytes);
    int offset = 1;

    if (type == PDBTYPE.LIST) {
      while (offset < bytes.length) {
        final decoded = _decodeValueV1(bytes, byteData, offset);
        pdb._listData.add(decoded.value);
        offset = decoded.nextOffset;
      }
    } else {
      while (offset < bytes.length) {
        final decodedKey = _decodeKeyV1(bytes, byteData, offset);
        offset = decodedKey.nextOffset;

        final decodedVal = _decodeValueV1(bytes, byteData, offset);
        offset = decodedVal.nextOffset;

        pdb._mapData[decodedKey.value] = decodedVal.value;
      }
    }

    return pdb;
  }

  static Future<Pdb> _openV2(Uint8List bytes, PDBTYPE type) async {
    final countRead = Varint.readUnsigned(bytes, 2);
    final entryCount = countRead.value;
    int offset = countRead.nextOffset;

    final pdb = Pdb(
      dataType: type,
      expectedSize: type == PDBTYPE.LIST ? entryCount : null,
    );

    if (type == PDBTYPE.LIST) {
      for (var i = 0; i < entryCount; i++) {
        final decoded = _decodeValueV2(bytes, offset);
        pdb._listData.add(decoded.value);
        offset = decoded.nextOffset;
      }
    } else {
      for (var i = 0; i < entryCount; i++) {
        final decodedKey = _decodeKeyV2(bytes, offset);
        offset = decodedKey.nextOffset;

        final decodedVal = _decodeValueV2(bytes, offset);
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
    builder.addByte(
      dataType == PDBTYPE.LIST ? TypeTag.listDatabase : TypeTag.mapDatabase,
    );
    builder.addByte(TypeTag.formatVersion2);
    Varint.writeUnsigned(builder, length);

    if (dataType == PDBTYPE.LIST) {
      for (final item in _listData) {
        _encodeValueV2(builder, item);
      }
    } else {
      for (final entry in _mapData.entries) {
        _encodeKeyV2(builder, entry.key);
        _encodeValueV2(builder, entry.value);
      }
    }

    await file.create(recursive: true);
    await file.writeAsBytes(builder.toBytes());
  }

  void addInt(int value, {dynamic key}) => _validateAndSet(key, value);

  void addBool(bool value, {dynamic key}) => _validateAndSet(key, value);

  void addString(String value, {dynamic key}) => _validateAndSet(key, value);

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

  static void _encodeKeyV2(BytesBuilder builder, dynamic key) {
    if (key is int) {
      builder.addByte(TypeTag.intKey);
      Varint.write(builder, key);
    } else if (key is String) {
      builder.addByte(TypeTag.stringKey);
      final encoded = utf8.encode(key);
      Varint.writeUnsigned(builder, encoded.length);
      builder.add(encoded);
    } else {
      throw KeyTypeInvalid('Key type is invalid: ${key.runtimeType}');
    }
  }

  static void _encodeValueV2(BytesBuilder builder, dynamic value) {
    if (value == null) {
      builder.addByte(TypeTag.nullValue);
    } else if (value is bool) {
      builder.addByte(value ? TypeTag.booleanTrue : TypeTag.booleanFalse);
    } else if (value is int) {
      builder.addByte(TypeTag.intValue);
      Varint.write(builder, value);
    } else if (value is String) {
      builder.addByte(TypeTag.stringValue);
      final encoded = utf8.encode(value);
      Varint.writeUnsigned(builder, encoded.length);
      builder.add(encoded);
    } else {
      throw DatabaseBroken('Unsupported value type: ${value.runtimeType}');
    }
  }

  static _DecodedItem _decodeKeyV2(Uint8List bytes, int offset) {
    if (offset >= bytes.length) {
      throw DatabaseBroken('Corrupted database while reading key');
    }

    final tag = bytes[offset];
    offset += 1;

    if (tag == TypeTag.intKey) {
      final r = Varint.read(bytes, offset);
      return _DecodedItem(r.value, r.nextOffset);
    } else if (tag == TypeTag.stringKey) {
      final lenRead = Varint.readUnsigned(bytes, offset);
      final len = lenRead.value;
      final start = lenRead.nextOffset;
      if (start + len > bytes.length) {
        throw DatabaseBroken('Corrupted database reading string key bytes');
      }
      final key = utf8.decode(Uint8List.sublistView(bytes, start, start + len));
      return _DecodedItem(key, start + len);
    } else {
      throw DatabaseBroken('Invalid key tag: $tag');
    }
  }

  static _DecodedItem _decodeValueV2(Uint8List bytes, int offset) {
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
      final r = Varint.read(bytes, offset);
      return _DecodedItem(r.value, r.nextOffset);
    } else if (tag == TypeTag.stringValue) {
      final lenRead = Varint.readUnsigned(bytes, offset);
      final len = lenRead.value;
      final start = lenRead.nextOffset;
      if (start + len > bytes.length) {
        throw DatabaseBroken('Corrupted database reading string value bytes');
      }
      final value = utf8.decode(
        Uint8List.sublistView(bytes, start, start + len),
      );
      return _DecodedItem(value, start + len);
    } else {
      throw DatabaseBroken('Invalid value tag: $tag');
    }
  }

  static _DecodedItem _decodeKeyV1(
    Uint8List bytes,
    ByteData byteData,
    int offset,
  ) {
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
      final key = utf8.decode(
        Uint8List.sublistView(bytes, offset, offset + len),
      );
      return _DecodedItem(key, offset + len);
    } else {
      throw DatabaseBroken('Invalid key tag: $tag');
    }
  }

  static _DecodedItem _decodeValueV1(
    Uint8List bytes,
    ByteData byteData,
    int offset,
  ) {
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
      final value = utf8.decode(
        Uint8List.sublistView(bytes, offset, offset + len),
      );
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
