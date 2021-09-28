class AutoInjectInit {
  final String initializerName;

  const AutoInjectInit({required this.initializerName});
}

class Injectable {
  final Type? as;

  final List<String> env;

  const Injectable({this.as, this.env = const []});
}

class Singleton extends Injectable {
  final Function? dispose;

  const Singleton({this.dispose, Type? as, List<String> env = const []}) : super(as: as, env: env);
}

class LazySingleton extends Singleton {
  const LazySingleton({Function? dispose, Type? as, List<String> env = const []})
      : super(dispose: dispose, as: as, env: env);
}

class Module {
  const Module._();
}

const module = Module._();

class DisposeMethod {
  const DisposeMethod._();
}

const disposeMethod = DisposeMethod._();
