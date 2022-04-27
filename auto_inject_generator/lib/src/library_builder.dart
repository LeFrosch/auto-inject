part of 'library_generator.dart';

Reference getItReference() => refer('GetIt', 'package:get_it/get_it.dart');

String getBuildFunctionNameFromEnv(String env) => '_buildEnv${env[0].toUpperCase()}${env.substring(1)}';

class AutoInjectLibraryBuilder {
  static final _getItInstanceName = 'getItInstance';

  static final _initMethodName = 'initAutoInject';
  static final _initGetItName = 'getItInstance';
  static final _initEnvName = 'environment';

  static final _moduleTypeChecker = TypeChecker.fromRuntime(Module);
  static final _testModuleTypeChecker = TypeChecker.fromRuntime(TestModule);
  static final _factoryTypeChecker = TypeChecker.fromRuntime(AssistedFactory);

  final LibraryBuilder libraryBuilder;
  final List<LibraryReader> reader;
  final List<LibraryElement> libraries;

  final Map<String, List<Node>> dependencies;
  final Map<String, List<Node>> assistedDependencies;

  final List<ModuleParserResult> modules;
  final List<TestModuleParserResult> testModules;

  AutoInjectLibraryBuilder({
    required this.libraryBuilder,
    required this.reader,
    required this.libraries,
  })  : dependencies = {},
        assistedDependencies = {},
        modules = [],
        testModules = [];

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
      modules.add(result);

      libraryBuilder.body.add(Class(
        (builder) => builder
          ..name = moduleClassNameFromId(result.id)
          ..extend = result.reference,
      ));

      _addDependencies(result.dependencies);
    }
  }

  void parseTestModules(String testEnv) {
    for (final moduleElement in _annotatedWith(_testModuleTypeChecker)) {
      final result = TestModuleParser.parse(libraries, moduleElement, testEnv);
      testModules.add(result);

      _addDependencies({testEnv: result.dependencies});
    }
  }

  void parseFactories() {
    for (final factoryElement in _annotatedWith(_factoryTypeChecker)) {
      final result = FactoryParser.parse(libraries, factoryElement);

      for (final env in dependencies.keys) {
        final source = FactorySource(result, env);

        dependencies[env]!.add(Node.fromTypes(
          libraries: libraries,
          parameters: [],
          groups: [],
          type: result.type,
          source: source,
        ));
      }
    }
  }

  void parseGroups() {
    for (final env in dependencies.keys) {
      final envDependencies = dependencies[env]!;
      final groups = envDependencies.map((e) => e.groups).flattened.toSet();

      for (final group in groups) {
        final source = GroupSource(
          groupType: resolveDartType(libraries, group.type),
          members: envDependencies.where((e) => e.groupIds.contains(group.id)).map((e) => e.source.type).toList(),
          env: env,
          id: group.id,
        );

        envDependencies.add(Node(
          nodeId: Object.hash(group.id, 'Group'),
          groups: [],
          dependencies: [],
          groupDependencies: [],
          source: source,
        ));
      }
    }
  }

  void parseClasses() {
    for (final classElement in _annotatedWith(AnnotationParser.classAnnotation)) {
      final result = ClassParser.parse(libraries, classElement);

      _addDependency(result);
    }
  }

  void _buildEnv(String env, MethodBuilder builder, Iterable<Code> modules) {
    final dependencies = this.dependencies[env]!;
    for (final dependency in dependencies) {
      libraryBuilder.body.addAll(dependency.source.createGlobal(dependencies.whereNot((e) => e == dependency)));
    }

    final sortedDependencies = topologicalSort(dependencies, env);

    builder.name = getBuildFunctionNameFromEnv(env);
    builder.returns = refer('void');

    builder.requiredParameters.add(
      Parameter((builder) => builder
        ..name = _getItInstanceName
        ..type = getItReference()),
    );
    builder.body = Block.of([
      ...modules,
      ...sortedDependencies
          .where((e) => e.source.canSupply)
          .map((e) => e.source.create(refer(_getItInstanceName)).statement),
    ]);
  }

  void buildEnv(String env) {
    final modulesInstances = modules.map(
      (e) => refer(moduleClassNameFromId(e.id)).newInstance([]).assignFinal(moduleInstanceNameFromId(e.id)).statement,
    );

    libraryBuilder.body.add(Method((builder) => _buildEnv(env, builder, modulesInstances)));
  }

  void buildTestEnv(String env) {
    final modulesInstances = [
      ...modules.map(
        (e) => refer(moduleClassNameFromId(e.id)).newInstance([]).assignFinal(moduleInstanceNameFromId(e.id)).statement,
      ),
      ...testModules.map(
        (e) => refer(e.name).assignFinal(e.moduleName).statement,
      ),
    ];

    libraryBuilder.body.add(Method((builder) {
      _buildEnv(env, builder, modulesInstances);

      builder.optionalParameters.addAll(
        testModules.map((e) => Parameter((builder) => TestModuleParser.buildEnvMethodParameter(builder, e))),
      );
    }));
  }

  void buildInitMethod(String? testEnv) {
    libraryBuilder.body.add(Method((builder) => builder
      ..name = _initMethodName
      ..requiredParameters.add(
        Parameter(
          (builder) => builder
            ..name = _initGetItName
            ..type = getItReference(),
        ),
      )
      ..optionalParameters.add(
        Parameter(
          (builder) => builder
            ..name = _initEnvName
            ..type = refer('String')
            ..named = true
            ..required = true,
        ),
      )
      ..optionalParameters.addAll(
        testModules.map((e) => Parameter((builder) => TestModuleParser.buildInitMethodParameter(builder, e))),
      )
      ..returns = refer('void')
      ..body = Block.of([
        Code('switch ($_initEnvName) {'),
        for (final env in dependencies.keys)
          Block.of([
            Code('case \'$env\':'),
            if (env == testEnv)
              refer(getBuildFunctionNameFromEnv(env)).call(
                [refer(_initGetItName)],
                TestModuleParser.callEnvMethodArgument(testModules),
              ).statement
            else
              refer(getBuildFunctionNameFromEnv(env)).call([refer(_initGetItName)]).statement,
            Code('break;'),
          ]),
        const Code('}'),
      ])));
  }
}
