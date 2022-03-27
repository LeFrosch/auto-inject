part of 'factory_parser.dart';

class FactoryFunction {
  final List<ParameterParserResult> parameters;
  final Reference returnType;
  final String name;
  final int id;

  FactoryFunction({
    required this.parameters,
    required this.returnType,
    required this.name,
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
      returnType: resolveDartType(libraries, element.returnType),
      name: element.name,
      id: resolveDartTypeToId(libraries, element.returnType),
    );

    results.add(result);
  }
}
