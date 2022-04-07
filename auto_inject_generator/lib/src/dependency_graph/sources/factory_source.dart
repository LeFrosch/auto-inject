part of 'dependency_source.dart';

class FactorySource extends DependencySource {
  static final _getItInstanceName = '_getInstance';

  final FactoryParserResult result;
  final String env;

  FactorySource(this.result, this.env) : super(type: result.reference);

  String get name => '_Factory${result.id}$env';

  void _createMethod(MethodBuilder builder, FactoryFunction function, Node? node, String env) {
    builder.name = function.name;
    builder.returns = function.returnType;
    builder.annotations.add(refer('override'));

    final params = function.parameters.map((e) => Parameter(
          (builder) => builder
            ..named = e.named
            ..name = e.name
            ..type = e.reference,
        ));

    builder.requiredParameters.addAll(params);

    if (node == null) {
      log.warning('Return type ${function.returnType.symbol} of ${function.name} cannot be found in $env');
      builder.lambda = true;
      builder.body = Code("throw UnimplementedError('Not available in $env')");
    } else {
      builder.body = node.source.create(refer(_getItInstanceName)).code;
    }
  }

  Iterable<Method> _createMethods(List<FactoryFunction> functions, Iterable<Node> dependencies, String env) sync* {
    for (final function in functions) {
      final result = dependencies.firstWhereOrNull((e) => e.nodeId == function.id);

      yield Method((builder) => _createMethod(builder, function, result, env));
    }
  }

  void _createGetItField(FieldBuilder builder) {
    builder.name = _getItInstanceName;
    builder.type = getItReference();
    builder.modifier = FieldModifier.final$;
  }

  void _createConstructor(ConstructorBuilder builder) {
    builder.requiredParameters.add(Parameter(
      (builder) => builder
        ..toThis = true
        ..name = _getItInstanceName,
    ));
  }

  @override
  Iterable<Spec> createGlobal(Iterable<Node> dependencies) => [
        Class(
          (builder) => builder
            ..name = name
            ..extend = type
            ..fields.add(Field(_createGetItField))
            ..constructors.add(Constructor(_createConstructor))
            ..methods.addAll(_createMethods(result.functions, dependencies, env)),
        )
      ];

  @override
  Expression create(Reference getItInstance) {
    return registerSingleton(
      getItInstance: getItInstance,
      type: type,
      createInstance: refer(name).newInstance([getItInstance]),
      dispose: null,
    );
  }
}
