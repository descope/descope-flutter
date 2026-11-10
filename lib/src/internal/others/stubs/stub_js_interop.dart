// Stub file for non-web platforms
class JS {
  final String? name;
  const JS([this.name]);
}

class JSAny {}

class JSFunction extends JSAny {}

class JSBoolean extends JSAny {
  final bool _value;
  JSBoolean(this._value);

  bool get toDart => _value;
}

class JSString extends JSAny {
  final String _value;
  JSString(this._value);

  String get toDart => _value;
}

class JSPromise<T> extends JSAny {
  final T _value;
  JSPromise(this._value);

  Future<T> get toDart async => _value;
}

extension StringToJS on String {
  JSString get toJS => JSString(this);
}

extension FunctionToJS on Function {
  JSFunction get toJS => JSFunction();
}
