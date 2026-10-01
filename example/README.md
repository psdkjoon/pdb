# pdb examples

These files are meant to be read top to bottom, in order — each one builds
on the last. Every line that does something non-obvious has a comment
explaining *why*, not just *what*.

| File | What it shows |
|---|---|
| `01_basics_list.dart` | Creating a LIST database: add/read/save/load by position, plus `isEmpty`, `contains`, `removeAt`, `toList`, `all`, `clear`. |
| `02_basics_map.dart` | Creating a MAP database: add/read/save/load by key, plus storing `null` on purpose, `containsKey`, `remove`, `keys`, `values`, `toMap`. |
| `03_recipe_box.dart` | A realistic combined example — a LIST "index" plus one MAP file per item — and the common "open if it exists, else create" startup pattern. |
| `04_errors_and_edge_cases.dart` | Every exception `pdb` can throw (`PairOnList`, `SingleValueOnMap`, `KeyTypeInvalid`, `DatabaseFileDoesNotExist`, `DatabaseFileExist`, `DatabaseBroken`), triggered one at a time with an explanation of what caused it and how to avoid or recover from it. |

Together, these four files touch every public method on `Pdb` and every
exception type in the package — if you've run all four, you've seen the
whole public API in action at least once.

## Running an example

From inside the package's root folder (the one with `pubspec.yaml` in it):

```bash
dart pub get
dart run example/01_basics_list.dart
dart run example/02_basics_map.dart
dart run example/03_recipe_box.dart
dart run example/04_errors_and_edge_cases.dart
```

Each script creates its own small `.pdb` file in the current folder so you
can inspect it. These are only example data — delete the generated
`*.pdb` files afterwards if you want to clean up; the package itself
doesn't need them.
