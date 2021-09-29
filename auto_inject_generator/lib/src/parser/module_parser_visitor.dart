part of 'module_parser.dart';

enum ModuleAccessType { method, property }

class ModuleAccess {
  final ModuleAccessType type;
  final String name;

  ModuleAccess({
    required this.type,
    required this.name,
  });
}

class _ModuleVisitorResult {
  final AnnotationParserResult annotation;
  final List<ParameterParserResult> dependencies;
  final ModuleAccess access;
  final DartType type;

  _ModuleVisitorResult({
    required this.annotation,
    required this.dependencies,
    required this.access,
    required this.type,
  });
}

class _ModuleVisitor extends SimpleElementVisitor<void> {
  final List<_ModuleVisitorResult> results;
  final List<LibraryElement> libraries;

  _ModuleVisitor(this.libraries) : results = [];

  void _visitElement({
    required List<ParameterElement> dependencies,
    required DartType sourceType,
    required Element element,
    required ModuleAccess access,
  }) {
    final annotation = AnnotationParser.annotationTypeChecker.firstAnnotationOf(element);

    if (annotation != null) {
      final result = _ModuleVisitorResult(
        annotation: AnnotationParser.parse(libraries, sourceType, annotation),
        dependencies: dependencies.map((dependency) => ParameterParser.parse(libraries, dependency)).toList(),
        access: access,
        type: sourceType,
      );

      results.add(result);
    }
  }

  @override
  void visitMethodElement(MethodElement element) => _visitElement(
        dependencies: element.parameters,
        sourceType: element.returnType,
        element: element,
        access: ModuleAccess(type: ModuleAccessType.method, name: element.name),
      );

  @override
  void visitPropertyAccessorElement(PropertyAccessorElement element) => _visitElement(
        dependencies: [],
        sourceType: element.returnType,
        element: element,
        access: ModuleAccess(type: ModuleAccessType.property, name: element.name),
      );
}
