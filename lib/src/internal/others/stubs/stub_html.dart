// stub window & document
class StubWindow {
  final localStorage = <String, String>{};
  String? origin = "";
}

class StubDocument {
  StubHtml? head;
  StubHtml? body;
}

class StubHtml {
  final children = <Element>[];
}

final window = StubWindow();
final document = StubDocument();

Iterable<Element> querySelectorAll(String _) => <Element>[];

// stub html elements
class NodeValidatorBuilder {
  NodeValidatorBuilder.common();

  allowElement(String _, {Iterable<String>? attributes}) => this;
}

class Element {
  Element();

  Element.html(String _, {NodeValidatorBuilder? validator});

  remove() => {};

  addEventListener(String _, EventListener? __) => {};

  removeEventListener(String _, EventListener? __) => {};
  String? className;
}

class DivElement extends Element {
  final children = <Element>[];
}

class ScriptElement extends Element {
  String text = "";
}

// stub events
typedef EventListener = Function(Event event);

class Event {}

class CustomEvent {
  final dynamic detail = <dynamic, dynamic>{};
}

// others
class Platform {}
