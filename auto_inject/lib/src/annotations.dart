class Injectable {
  final Type? as;
  final List<Type> group;

  final List<String> env;

  const Injectable({this.as, required this.env, this.group = const []});
}

class AssistedInjectable extends Injectable {
  const AssistedInjectable({Type? as, required List<String> env}) : super(as: as, env: env, group: const []);
}

class Singleton extends Injectable {
  final Function? dispose;

  const Singleton({this.dispose, Type? as, required List<String> env, List<Type> group = const []})
      : super(as: as, env: env, group: group);
}

class LazySingleton extends Singleton {
  const LazySingleton({Function? dispose, Type? as, required List<String> env, List<Type> group = const []})
      : super(dispose: dispose, as: as, env: env, group: group);
}

class Module {
  const Module._();
}

const module = Module._();

class TestModule {
  final String name;

  const TestModule(this.name);
}

class AssistedFactory {
  const AssistedFactory._();
}

const assistedFactory = AssistedFactory._();

class DisposeMethod {
  const DisposeMethod._();
}

const disposeMethod = DisposeMethod._();

class AssistedField {
  final String? name;

  const AssistedField([this.name]);
}

const assistedField = AssistedField();

class GroupField {
  const GroupField._();
}

const groupField = GroupField._();
