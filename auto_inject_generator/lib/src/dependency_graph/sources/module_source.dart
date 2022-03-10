part of 'dependency_source.dart';

String moduleInstanceNameFromId(int id) => '_module$id';
String moduleClassNameFromId(int id) => '_Module$id';

abstract class ModuleSource extends DependencySource {
  final int moduleId;
  final List<ParameterParserResult> parameter;
  final ModuleAccess access;

  const ModuleSource({
    required this.moduleId,
    required this.parameter,
    required this.access,
    required Reference type,
  }) : super(type: type);

  factory ModuleSource.fromAnnotation({
    required int moduleId,
    required List<ParameterParserResult> parameter,
    required Reference type,
    required ModuleAccess access,
    required AnnotationParserResult annotation,
  }) {
    switch (annotation.type) {
      case AnnotationType.injectable:
        return _ModuleInjectable(
          moduleId: moduleId,
          parameter: parameter,
          access: access,
          type: type,
        );
      case AnnotationType.singleton:
        return _ModuleSingleton(
          moduleId: moduleId,
          parameter: parameter,
          access: access,
          type: type,
          dispose: annotation.dispose,
        );
      case AnnotationType.lazySingleton:
        return _ModuleLazySingleton(
          moduleId: moduleId,
          parameter: parameter,
          access: access,
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
        param.name!: retrieveFromGetIt(getItInstance: getItInstance, type: param.reference)
    };

    final instanceName = moduleInstanceNameFromId(moduleId);
    switch (access.type) {
      case ModuleAccessType.method:
        return refer(instanceName).property(access.name).call(positional, named);
      case ModuleAccessType.property:
        return refer(instanceName).property(access.name);
    }
  }
}

class _ModuleInjectable extends ModuleSource {
  const _ModuleInjectable({
    required int moduleId,
    required List<ParameterParserResult> parameter,
    required ModuleAccess access,
    required Reference type,
  }) : super(
          moduleId: moduleId,
          parameter: parameter,
          access: access,
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

class _ModuleSingleton extends ModuleSource {
  final DisposeResult? dispose;

  const _ModuleSingleton({
    required int moduleId,
    required List<ParameterParserResult> parameter,
    required ModuleAccess access,
    required Reference type,
    required this.dispose,
  }) : super(
          moduleId: moduleId,
          parameter: parameter,
          access: access,
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

class _ModuleLazySingleton extends ModuleSource {
  final DisposeResult? dispose;

  const _ModuleLazySingleton({
    required int moduleId,
    required List<ParameterParserResult> parameter,
    required ModuleAccess access,
    required Reference type,
    required this.dispose,
  }) : super(
          moduleId: moduleId,
          parameter: parameter,
          access: access,
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
