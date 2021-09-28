part of 'library_generator.dart';

class AutoInjectLibraryBuilder {
  static final _moduleTypeChecker = TypeChecker.fromRuntime(Module);

  final LibraryBuilder libraryBuilder;
  final List<LibraryReader> reader;
  final List<LibraryElement> libraries;

  final Map<String, List<Node>> dependencies;

  AutoInjectLibraryBuilder({
    required this.libraryBuilder,
    required this.reader,
    required this.libraries,
  }) : dependencies = {};

  Iterable<AnnotatedElement> _annotatedWith(TypeChecker checker) =>
      reader.map((e) => e.annotatedWith(checker)).flattened;

  void parseModules() {
    for (final moduleElement in _annotatedWith(_moduleTypeChecker)) {
      final result = ModuleParser.parse(libraries, moduleElement);
      print('Registered module: ${result.name}');

      final moduleClass = Class((builder) => builder
        ..name = '_${result.name}Impl'
        ..extend = result.reference);
      libraryBuilder.body.add(moduleClass);

      for (final dependenciesEnv in result.dependencies.entries) {
        dependencies.putIfAbsent(dependenciesEnv.key, () => []).addAll(dependenciesEnv.value);
      }
    }
  }
}
