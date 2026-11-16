import '/src/internal/others/stubs/stub_js_interop.dart';

// stub window & document
class StubWindow {
  final localStorage = Storage();
  final sessionStorage = Storage();
  final navigator = StubNavigator();
  final location = StubLocation();
}

class StubDocument {
  Element? head;
  Element? body;

  Element createElement(String _) => Element();

  Element? querySelector(String _) => null;
}

class StubNavigator {
  String userAgent = "";
  String vendor = "";
}

class StubLocation {
  String origin = "";
}

class Storage {
  final _items = <String, String>{};

  String? getItem(String key) => _items[key];

  void setItem(String key, String value) => _items[key] = value;

  void removeItem(String key) => _items.remove(key);

  void clear() => _items.clear();
}

final window = StubWindow();
final document = StubDocument();

// stub html elements
class Element {
  String className = "";
  String text = "";
  String src = "";
  String textContent = "";
  Element? parentElement;

  void setAttribute(String _, String __) {}

  Element appendChild(Element node) => node;

  void remove() {}

  void addEventListener(String _, EventListener? __) {}

  void removeEventListener(String _, EventListener? __) {}
}

class HTMLScriptElement extends Element {}

// stub events
typedef EventListener = JSFunction;

class Event {}

class CustomEvent extends Event {
  JSAny? detail;
}
