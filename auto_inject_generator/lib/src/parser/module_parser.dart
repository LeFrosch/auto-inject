import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:auto_inject_generator/src/dependency_graph/node.dart';
import 'package:auto_inject_generator/src/parser/annotation_parser.dart';
import 'package:auto_inject_generator/src/parser/utils.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

class ModuleParserResult {
  final int id;
  final String name;
  final Reference reference;
  final Map<String, List<Node>> dependencies;

  ModuleParserResult({
    required this.id,
    required this.name,
    required this.reference,
    required this.dependencies,
  });

  Iterable<String> get environments => dependencies.keys;
}

abstract class ModuleParser {
  static int _moduleIdCounter = 0;

  static ModuleParserResult parse(List<LibraryElement> libraries, AnnotatedElement element) {
    final classElement = element.element;
    if (classElement is! ClassElement) {
      throw UnsupportedError('${classElement.name} is not a Class, only annotate abstract class with @module');
    }
    if (!classElement.isAbstract) {
      throw UnsupportedError('${classElement.name} is not abstract, only annotate abstract class with @module');
    }

    final constructor = classElement.unnamedConstructor;
    if (constructor == null) {
      throw UnsupportedError(
        '${classElement.name} has no default constructor, classes annotated with @module must have a default constructor',
      );
    }
    if (constructor.parameters.isNotEmpty) {
      throw UnsupportedError(
        'the default constructor of ${classElement.name} requires arguments, classes annotated with @module must have a default constructor with no arguments',
      );
    }

    final id = _moduleIdCounter++;

    final reference = TypeReference((builder) => builder
      ..isNullable = false
      ..symbol = classElement.name
      ..url = resolveImport(libraries, classElement));

    final visitor = _ModuleVisitor(libraries);
    classElement.visitChildren(visitor);

    print(visitor.results.length);

    return ModuleParserResult(id: id, name: classElement.name, reference: reference, dependencies: {});
  }
}

class _ModuleVisitor extends SimpleElementVisitor<void> {
  final List<AnnotationParserResult> results;
  final List<LibraryElement> libraries;

  _ModuleVisitor(this.libraries) : results = [];

  void _visitElement(DartType sourceType, Element element) {
    final annotation = AnnotationParser.annotationTypeChecker.firstAnnotationOf(element);

    if (annotation != null) {
      results.add(AnnotationParser.parse(libraries, sourceType, annotation));
    }
  }

  @override
  void visitMethodElement(MethodElement element) => _visitElement(element.returnType, element);

  @override
  void visitPropertyAccessorElement(PropertyAccessorElement element) => _visitElement(element.returnType, element);
}
