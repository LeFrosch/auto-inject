part of 'factory_parser.dart';

class FactoryFunction {
  final List<ParameterParserResult> parameters;
  final DartType type;
  final int id;

  FactoryFunction({
    required this.parameters,
    required this.type,
    required this.id,
  });
}

class _FactoryVisitor extends SimpleElementVisitor<void> {
  final List<FactoryFunction> results;
  final List<LibraryElement> libraries;

  _FactoryVisitor(this.libraries) : results = [];

  @override
  void visitMethodElement(MethodElement element) {
    if (!element.isAbstract) {
      log.warning('${element.enclosingElement.name}.${element.name} is not abstract');
      return;
    }

    final result = FactoryFunction(
      parameters: element.parameters.map((e) => ParameterParser.parse(libraries, e)).toList(),
      type: element.returnType,
      id: resolveDartTypeToId(libraries, element.returnType),
    );

    results.add(result);
  }
}
