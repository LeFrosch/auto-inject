part of 'module_parser.dart';

class TestModuleParserResult {
  final Reference reference;
  final List<Node> dependencies;

  final String name;
  final String moduleName;

  TestModuleParserResult({
    required this.reference,
    required this.dependencies,
    required this.name,
    required this.moduleName,
  });
}

abstract class TestModuleParser {
  static TestModuleParserResult parse(List<LibraryElement> libraries, AnnotatedElement element, String testEnv) {
    final moduleResult = ModuleParser.parse(libraries, element);

    final dependencies = moduleResult.dependencies[testEnv];
    if (dependencies == null) {
      log.warning('${element.element.name} is a test module but does not define any test dependencies');
    }

    return TestModuleParserResult(
      reference: moduleResult.reference,
      dependencies: dependencies ?? [],
      name: element.annotation.read('name').stringValue,
      moduleName: moduleInstanceNameFromId(moduleResult.id),
    );
  }

  static void buildEnvMethodParameter(ParameterBuilder builder, TestModuleParserResult result) {
    builder.name = result.name;
    builder.type = result.reference;
    builder.required = true;
    builder.named = true;
  }

  static void buildInitMethodParameter(ParameterBuilder builder, TestModuleParserResult result) {
    builder.name = result.name;
    builder.type = TypeReference((builder) {
      final ref = result.reference;

      builder.isNullable = true;
      builder.symbol = ref.symbol;
      builder.url = ref.url;

      if (ref is TypeReference) {
        builder.types.addAll(ref.types);
      }
    });
    builder.named = true;
  }

  static Map<String, Expression> callEnvMethodArgument(List<TestModuleParserResult> results) {
    return {
      for (final result in results) result.name: refer(result.name).nullChecked,
    };
  }
}
