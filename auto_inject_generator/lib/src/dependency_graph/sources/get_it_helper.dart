import 'package:code_builder/code_builder.dart';

Expression retrieveFromGetIt({
  required Reference getItInstance,
  required Reference type,
}) {
  return getItInstance.call([], {}, [type]);
}

Expression registerSingleton({
  required Reference getItInstance,
  required Reference type,
  required Expression createInstance,
}) {
  return getItInstance.property('registerSingleton').call([createInstance], {}, [type]);
}

Expression registerLazySingleton({
  required Reference getItInstance,
  required Reference type,
  required Expression createInstance,
}) {
  final factoryFunction = Method((b) => b..body = createInstance.code).closure;

  return getItInstance.property('registerLazySingleton').call([factoryFunction], {}, [type]);
}
