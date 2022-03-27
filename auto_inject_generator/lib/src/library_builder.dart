part of 'library_generator.dart';

String getBuildFunctionNameFromEnv(String env) => '_buildEnv${env[0].toUpperCase()}${env.substring(1)}';

class AutoInjectLibraryBuilder {
  static final _getItInstanceName = 'getItInstance';
  static final _getItReference = refer('GetIt', 'package:get_it/get_it.dart');

  static final _initMethodName = 'initAutoInject';
  static final _initGetItName = 'getItInstance';
  static final _initEnvName = 'environment';

  static final _moduleTypeChecker = TypeChecker.fromRuntime(Module);
  static final _factoryTypeChecker = TypeChecker.fromRuntime(AssistedFactory);

  final LibraryBuilder libraryBuilder;
  final List<LibraryReader> reader;
  final List<LibraryElement> libraries;

  final Map<String, List<Node>> dependencies;
  final Map<String, List<Node>> assistedDependencies;

  late final MethodBuilder initMethodBuilder;

  AutoInjectLibraryBuilder({
    required this.libraryBuilder,
    required this.reader,
    required this.libraries,
  })  : dependencies = {},
        assistedDependencies = {};

  Iterable<AnnotatedElement> _annotatedWith(TypeChecker checker) =>
      reader.map((e) => e.annotatedWith(checker)).flattened;

  void _addDependencies(Map<String, List<Node>> input) {
    for (final env in input.entries) {
      dependencies.putIfAbsent(env.key, () => []).addAll(env.value);
    }
  }

  void _addDependency(Map<String, Node> input) {
    for (final env in input.entries) {
      dependencies.putIfAbsent(env.key, () => []).add(env.value);
    }
  }

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

      _addDependencies(result.dependencies);
    }
  }

  void parseFactories() {
    for (final factoryElement in _annotatedWith(_factoryTypeChecker)) {
      final result = FactoryParser.parse(libraries, factoryElement);
    }
  }

  void parseClasses() {
    for (final classElement in _annotatedWith(AnnotationParser.classAnnotation)) {
      final result = ClassParser.parse(libraries, classElement);

      _addDependency(result);
    }
  }

  void buildEnv(String env) {
    final dependencies = this.dependencies[env]!;
    final sortedDependencies = topologicalSort(dependencies, env);

    libraryBuilder.body.add(Method((builder) => builder
      ..name = getBuildFunctionNameFromEnv(env)
      ..requiredParameters.add(Parameter((builder) => builder
        ..name = _getItInstanceName
        ..type = _getItReference))
      ..returns = refer('void')
      ..body = Block.of([
        for (final source in sortedDependencies.map((e) => e.source).whereNotNull())
          source.create(refer(_getItInstanceName)).statement
      ])));
  }

  void buildInitMethod() {
    libraryBuilder.body.add(Method((builder) => builder
      ..name = _initMethodName
      ..requiredParameters.addAll([
        Parameter((builder) => builder
          ..name = _initGetItName
          ..type = _getItReference),
      ])
      ..optionalParameters.addAll([
        Parameter((builder) => builder
          ..name = _initEnvName
          ..type = refer('String')
          ..named = true
          ..required = true),
      ])
      ..returns = refer('void')
      ..body = Block.of([
        Code('switch ($_initEnvName) {'),
        for (final env in dependencies.keys)
          Block.of([
            Code('case \'$env\':'),
            refer(getBuildFunctionNameFromEnv(env)).call([refer(_initGetItName)]).statement,
            Code('break;'),
          ]),
        const Code('}'),
      ])));
  }
}
