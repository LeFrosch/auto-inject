part of 'library_generator.dart';

String getBuildFunctionNameFromEnv(String env) => '_buildEnv$env';

class AutoInjectLibraryBuilder {
  static final _getItInstanceName = 'getItInstance';
  static final _getItReference = refer('GetIt', 'package:get_it/get_it.dart');

  static final _moduleTypeChecker = TypeChecker.fromRuntime(Module);

  final LibraryBuilder libraryBuilder;
  final List<LibraryReader> reader;
  final List<LibraryElement> libraries;

  final Map<String, List<Node>> dependencies;

  late final MethodBuilder initMethodBuilder;

  AutoInjectLibraryBuilder({
    required this.libraryBuilder,
    required this.reader,
    required this.libraries,
  }) : dependencies = {};

  Iterable<AnnotatedElement> _annotatedWith(TypeChecker checker) =>
      reader.map((e) => e.annotatedWith(checker)).flattened;

  void parseModules() {
    for (final moduleElement in _annotatedWith(_moduleTypeChecker)) {
      final result = ModuleParser.parse(libraries, moduleElement);
      final className = moduleClassNameFromId(result.id);
      final instanceName = moduleInstanceNameFromId(result.id);

      final moduleClass = Class((builder) => builder
        ..name = className
        ..extend = result.reference);
      final moduleInstance = refer(className).newInstance([]).assignFinal(instanceName).statement;

      libraryBuilder.body.addAll([moduleClass, moduleInstance]);

      for (final dependenciesEnv in result.dependencies.entries) {
        dependencies.putIfAbsent(dependenciesEnv.key, () => []).addAll(dependenciesEnv.value);
      }
    }
  }

  void buildEnv(String env) {
    final dependencies = this.dependencies[env]!;
    final sortedDependencies = topologicalSort(dependencies);

    libraryBuilder.body.add(Method((builder) => builder
      ..name = getBuildFunctionNameFromEnv(env)
      ..requiredParameters.add(Parameter((builder) => builder
        ..name = _getItInstanceName
        ..type = _getItReference))
      ..returns = refer('void')
      ..body = Block((builder) {
        for (final dependency in sortedDependencies) {
          builder.statements.add(dependency.source.create(refer(_getItInstanceName)).statement);
        }
      })));
  }

  void buildInitMethod() {}
}
