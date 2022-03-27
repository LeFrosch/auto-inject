import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:auto_inject_generator/src/parser/parameter_parser.dart';
import 'package:auto_inject_generator/src/parser/utils.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

part 'factory_parser_visitor.dart';

class FactoryParserResult {
  final int id;
  final Reference reference;
  final DartType type;
  final List<FactoryFunction> functions;

  FactoryParserResult({
    required this.id,
    required this.reference,
    required this.type,
    required this.functions,
  });
}

abstract class FactoryParser {
  static int _factoryIdCounter = 0;

  static FactoryParserResult parse(List<LibraryElement> libraries, AnnotatedElement element) {
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

    final id = _factoryIdCounter++;

    final reference = TypeReference((builder) => builder
      ..isNullable = false
      ..symbol = classElement.name
      ..url = resolveImport(libraries, classElement));

    final visitor = _FactoryVisitor(libraries);
    classElement.visitChildren(visitor);

    return FactoryParserResult(
      id: id,
      reference: reference,
      type: classElement.thisType,
      functions: visitor.results,
    );
  }
}
