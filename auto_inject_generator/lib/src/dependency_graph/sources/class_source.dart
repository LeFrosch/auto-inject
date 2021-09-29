part of 'dependency_source.dart';

abstract class ClassSource extends DependencySource {
  final List<ParameterParserResult> parameter;
  final Reference classType;

  const ClassSource({
    required this.parameter,
    required this.classType,
    required Reference type,
  }) : super(type: type);

  factory ClassSource.fromAnnotation({
    required List<ParameterParserResult> parameter,
    required Reference type,
    required Reference classType,
    required AnnotationParserResult annotation,
  }) {
    switch (annotation.type) {
      case AnnotationType.injectable:
        return _ClassInjectable(
          parameter: parameter,
          classType: classType,
          type: type,
        );
      case AnnotationType.singleton:
        return _ClassSingleton(
          parameter: parameter,
          classType: classType,
          type: type,
        );
      case AnnotationType.lazySingleton:
        return _ClassLazySingleton(
          parameter: parameter,
          classType: classType,
          type: type,
        );
    }
  }

  @protected
  Expression createInstance(Reference getItInstance) {
    final positional =
        parameter.where((p) => !p.named).map((e) => retrieveFromGetIt(getItInstance: getItInstance, type: e.reference));

    final named = {
      for (final param in parameter.where((p) => p.named))
        param.name!: retrieveFromGetIt(getItInstance: getItInstance, type: param.reference)
    };

    return classType.newInstance(positional, named);
  }

  Expression create(Reference getItInstance);
}

class _ClassInjectable extends ClassSource {
  const _ClassInjectable({
    required List<ParameterParserResult> parameter,
    required Reference classType,
    required Reference type,
  }) : super(
          parameter: parameter,
          classType: classType,
          type: type,
        );

  @override
  Expression create(Reference getItInstance) {
    return literalString('injectable');
  }
}

class _ClassSingleton extends ClassSource {
  const _ClassSingleton({
    required List<ParameterParserResult> parameter,
    required Reference classType,
    required Reference type,
  }) : super(
          parameter: parameter,
          classType: classType,
          type: type,
        );

  @override
  Expression create(Reference getItInstance) {
    return registerSingleton(
      getItInstance: getItInstance,
      type: type,
      createInstance: createInstance(getItInstance),
    );
  }
}

class _ClassLazySingleton extends ClassSource {
  const _ClassLazySingleton({
    required List<ParameterParserResult> parameter,
    required Reference classType,
    required Reference type,
  }) : super(
          parameter: parameter,
          classType: classType,
          type: type,
        );

  @override
  Expression create(Reference getItInstance) {
    return registerLazySingleton(
      getItInstance: getItInstance,
      type: type,
      createInstance: createInstance(getItInstance),
    );
  }
}