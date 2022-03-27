class Injectable {
  final Type? as;

  final List<String> env;

  const Injectable({this.as, required this.env});
}

class AssistedInjectable extends Injectable {
  const AssistedInjectable({Type? as, required List<String> env}) : super(as: as, env: env);
}

class Singleton extends Injectable {
  final Function? dispose;

  const Singleton({this.dispose, Type? as, required List<String> env}) : super(as: as, env: env);
}

class LazySingleton extends Singleton {
  const LazySingleton({Function? dispose, Type? as, required List<String> env})
      : super(dispose: dispose, as: as, env: env);
}

class Module {
  const Module._();
}

const module = Module._();

class AssistedFactory {
  const AssistedFactory._();
}

const assistedFactory = AssistedFactory._();

class DisposeMethod {
  const DisposeMethod._();
}

const disposeMethod = DisposeMethod._();

class Assisted {
  final String? name;

  const Assisted([this.name]);
}

const assisted = Assisted();
