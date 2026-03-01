// Stub file for non-web platforms
class JS {
  final String? name;
  const JS([this.name]);
}

class JSBoolean {
  final bool _value;
  const JSBoolean(this._value);

  bool get toDart => _value;
}

class JSString {
  final String _value;
  const JSString(this._value);

  String get toDart => _value;
}

class JSPromise<T> {
  final T _value;
  const JSPromise(this._value);

  Future<T> get toDart async => _value;
}

extension StringToJS on String {
  JSString get toJS => JSString(this);
}
