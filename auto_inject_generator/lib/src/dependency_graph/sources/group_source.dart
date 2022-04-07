part of 'dependency_source.dart';

class GroupSource extends DependencySource {
  static final _getItInstanceName = '_getInstance';

  final String env;
  final int id;

  final Reference groupType;
  final List<Reference> members;

  GroupSource({required this.groupType, required this.members, required this.env, required this.id})
      : super(
          type: TypeReference(
            (builder) => builder
              ..symbol = 'GroupProvider'
              ..url = 'package:auto_inject/auto_inject.dart'
              ..types.add(groupType),
          ),
        );

  String get name => '_GroupSource$id$env';

  void _createMethod(MethodBuilder builder) {
    builder.name = 'call';
    builder.annotations.add(refer('override'));
    builder.lambda = true;
    builder.returns = TypeReference(
      (builder) => builder
        ..symbol = 'Iterable'
        ..types.add(groupType),
    );

    builder.body = Block.of([
      Code('['),
      ...members.map(
        (e) => Block.of([
          retrieveFromGetIt(getItInstance: refer(_getItInstanceName), type: e).code,
          Code(','),
        ]),
      ),
      Code(']'),
    ]);
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
            ..methods.add(Method(_createMethod)),
        ),
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
