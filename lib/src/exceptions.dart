class SingleValueOnMap implements Exception {
  final String message;

  SingleValueOnMap(this.message);

  @override
  String toString() => message;
}

class PairOnList implements Exception {
  final String message;

  PairOnList(this.message);

  @override
  String toString() => message;
}

class DatabaseFileDoesNotExist implements Exception {
  final String message;

  DatabaseFileDoesNotExist(this.message);

  @override
  String toString() => message;
}

class DatabaseFileExist implements Exception {
  final String message;

  DatabaseFileExist(this.message);

  @override
  String toString() => message;
}

class DatabaseBroken implements Exception {
  final String message;

  DatabaseBroken(this.message);

  @override
  String toString() => message;
}

class KeyTypeInvalid implements Exception {
  final String message;

  KeyTypeInvalid(this.message);

  @override
  String toString() => message;
}
