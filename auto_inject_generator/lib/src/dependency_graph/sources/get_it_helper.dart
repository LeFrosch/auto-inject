import 'package:code_builder/code_builder.dart';

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
  required Reference? dispose,
}) {
  final namedArgs = {if (dispose != null) 'dispose': dispose};

  return getItInstance.property('registerSingleton').call([createInstance], namedArgs, [type]);
}

Expression registerLazySingleton({
  required Reference getItInstance,
  required Reference type,
  required Expression createInstance,
  required Reference? dispose,
}) {
  final namedArgs = {if (dispose != null) 'dispose': dispose};
  final factoryFunction = Method((b) => b..body = createInstance.code).closure;

  return getItInstance.property('registerLazySingleton').call([factoryFunction], namedArgs, [type]);
}
