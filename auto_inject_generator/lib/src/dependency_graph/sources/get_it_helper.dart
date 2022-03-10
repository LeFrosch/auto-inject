import 'package:code_builder/code_builder.dart';

import '../../parser/annotation_parser.dart';

Expression? disposeMethodReference(DisposeResult? result) {
  if (result == null) return null;

  if (result.topLevel) {
    return result.method;
  } else {
    return Method(
      (builder) => builder
        ..lambda = true
        ..requiredParameters.add(Parameter((builder) => builder.name = 'obj'))
        ..body = Code.scope((a) => 'obj.${a(result.method)}()'),
    ).closure;
  }
}

Expression retrieveFromGetIt({
  required Reference getItInstance,
  required Reference type,
}) {
  return getItInstance.call([], {}, [type]);
}

Expression registerInjectable({
  required Reference getItInstance,
  required Reference type,
  required Expression createInstance,
}) {
  final factoryFunction = Method((b) => b..body = createInstance.code).closure;

  return getItInstance.property('registerFactory').call([factoryFunction], {}, [type]);
}

Expression registerSingleton({
  required Reference getItInstance,
  required Reference type,
  required Expression createInstance,
  required Expression? dispose,
}) {
  final namedArgs = {if (dispose != null) 'dispose': dispose};

  return getItInstance.property('registerSingleton').call([createInstance], namedArgs, [type]);
}

Expression registerLazySingleton({
  required Reference getItInstance,
  required Reference type,
  required Expression createInstance,
  required Expression? dispose,
}) {
  final namedArgs = {if (dispose != null) 'dispose': dispose};
  final factoryFunction = Method((b) => b..body = createInstance.code).closure;

  return getItInstance.property('registerLazySingleton').call([factoryFunction], namedArgs, [type]);
}
