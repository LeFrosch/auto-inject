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
      case AnnotationType.assisted:
        return _ClassAssistedInjectable(
          parameter: parameter,
          classType: classType,
          type: type,
        );
      case AnnotationType.singleton:
        return _ClassSingleton(
          parameter: parameter,
          classType: classType,
          type: type,
          dispose: annotation.dispose,
        );
      case AnnotationType.lazySingleton:
        return _ClassLazySingleton(
          parameter: parameter,
          classType: classType,
          type: type,
          dispose: annotation.dispose,
        );
    }
  }

  @protected
  Expression createInstance(Reference getItInstance) {
    final positional =
        parameter.where((p) => !p.named).map((e) => retrieveFromGetIt(getItInstance: getItInstance, type: e.reference));

    final named = {
      for (final param in parameter.where((p) => p.named))
        param.name: retrieveFromGetIt(getItInstance: getItInstance, type: param.reference)
    };

    return classType.newInstance(positional, named);
  }
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
    return registerInjectable(
      getItInstance: getItInstance,
      type: type,
      createInstance: createInstance(getItInstance),
    );
  }
}

class _ClassAssistedInjectable extends ClassSource with AssistedDependency {
  const _ClassAssistedInjectable({
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
    final positional = parameter
        .where((e) => !e.named && !e.assisted)
        .map((e) => retrieveFromGetIt(getItInstance: getItInstance, type: e.reference))
        .followedBy(parameter.where((e) => !e.named && e.assisted).map((e) => refer(e.name)));

    final named = {
      for (final param in parameter.where((e) => e.named && !e.assisted))
        param.name: retrieveFromGetIt(getItInstance: getItInstance, type: param.reference),
      for (final param in parameter.where((e) => e.named && e.assisted)) param.name: refer(param.name),
    };

    return classType.newInstance(positional, named);
  }
}

class _ClassSingleton extends ClassSource {
  final DisposeResult? dispose;

  const _ClassSingleton({
    required List<ParameterParserResult> parameter,
    required Reference classType,
    required Reference type,
    required this.dispose,
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
      dispose: disposeMethodReference(dispose),
    );
  }
}

class _ClassLazySingleton extends ClassSource {
  final DisposeResult? dispose;

  const _ClassLazySingleton({
    required List<ParameterParserResult> parameter,
    required Reference classType,
    required Reference type,
    required this.dispose,
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
      dispose: disposeMethodReference(dispose),
    );
  }
}
