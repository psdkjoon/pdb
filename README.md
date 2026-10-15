# pdb

A tiny, dependency-free binary key-value/list database for pure Dart.

## Install

```yaml
dependencies:
  pdb:
    path: ../pdb # or a git/pub source
```

## Usage

```dart
import 'package:pdb/pdb.dart';

// List database
final list = Pdb(dataType: PDBTYPE.LIST);
list.addString('hello');
list.addInt(42);
await list.save('data.pdb', replace: true);

final loadedList = await Pdb.open('data.pdb');
print(loadedList[0]); // hello

// Map database
final map = Pdb(dataType: PDBTYPE.MAP);
map.addString('Alice', key: 'name');
map.addInt(30, key: 'age');
await map.save('user.pdb', replace: true);

final loadedMap = await Pdb.open('user.pdb', create: true);
print(loadedMap.get('name')); // Alice
```

Supported value types: `int`, `bool`, `String`, `null`. Keys: `int` or `String`.

See `example/` for a full walkthrough, including every error type.

## License

See `LICENSE`.
