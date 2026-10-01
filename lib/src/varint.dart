import 'dart:typed_data';

import 'exceptions.dart';

class Varint {
  const Varint._();
  static int _zigZagEncode(int value) => (value << 1) ^ (value >> 63);
  static int _zigZagDecode(int value) => (value >> 1) ^ -(value & 1);

  static void write(BytesBuilder builder, int value) {
    var v = _zigZagEncode(value);
    while (true) {
      final byte = v & 0x7F;
      v = v >>> 7;
      if (v == 0) {
        builder.addByte(byte);
        break;
      } else {
        builder.addByte(byte | 0x80);
      }
    }
  }

  static ({int value, int nextOffset}) read(List<int> bytes, int offset) {
    int result = 0;
    int shift = 0;
    int pos = offset;

    while (true) {
      if (pos >= bytes.length) {
        throw DatabaseBroken('Corrupted database while reading varint');
      }
      final byte = bytes[pos];
      pos += 1;
      result |= (byte & 0x7F) << shift;
      if (byte & 0x80 == 0) break;
      shift += 7;
      if (shift > 63) {
        throw DatabaseBroken('Varint too long (corrupted database)');
      }
    }

    return (value: _zigZagDecode(result), nextOffset: pos);
  }

  static void writeUnsigned(BytesBuilder builder, int value) {
    if (value < 0) {
      throw ArgumentError('writeUnsigned requires a non-negative value');
    }
    var v = value;
    while (true) {
      final byte = v & 0x7F;
      v = v >>> 7;
      if (v == 0) {
        builder.addByte(byte);
        break;
      } else {
        builder.addByte(byte | 0x80);
      }
    }
  }

  static ({int value, int nextOffset}) readUnsigned(
    List<int> bytes,
    int offset,
  ) {
    int result = 0;
    int shift = 0;
    int pos = offset;

    while (true) {
      if (pos >= bytes.length) {
        throw DatabaseBroken('Corrupted database while reading varint');
      }
      final byte = bytes[pos];
      pos += 1;
      result |= (byte & 0x7F) << shift;
      if (byte & 0x80 == 0) break;
      shift += 7;
      if (shift > 63) {
        throw DatabaseBroken('Varint too long (corrupted database)');
      }
    }

    return (value: result, nextOffset: pos);
  }
}

final class Scratch {
  Scratch._();

  static final ByteData buf8 = ByteData(8);
  static final ByteData buf4 = ByteData(4);
}
