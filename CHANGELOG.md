## 1.2.0

- added create paramether for method open `Pdb.open(path, create: true)`

## 1.1.0

- `addInt`/`addBool`/`addString` are now synchronous (`void` instead of
  `Future<void>`) since they never touch disk — only `open()`/`save()` are
  async now.
- New on-disk format (v2): adds a varint entry-count header right after the
  type byte, and encodes all integers as zig-zag LEB128 varints instead of
  fixed 8-byte values. Small ints (the common case: indices, small IDs,
  counts) now cost 1-2 bytes instead of 9.
- String decoding no longer copies bytes via `sublist()` before calling
  `utf8.decode` — it decodes directly from a view into the original buffer,
  avoiding an extra allocation per string.
- List databases presize their backing storage from the header entry count
  on load, avoiding repeated doubling-reallocations while filling.
- `Pdb.open()` auto-detects old (v1) vs new (v2) files by a version byte, so
  existing `.pdb` files written by 1.0.0 keep loading correctly. Anything
  re-saved goes out in the new v2 format.

## 1.0.0

- Initial release.
