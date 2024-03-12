class StubWindow {
  final localStorage = Storage();
}

class Storage {
  String? operator [](Object? key) => null;

  void operator []=(String key, String value) {
  }

  String? remove(Object? key) {
    return null;
  }
}

class Platform {}

final window = StubWindow();
