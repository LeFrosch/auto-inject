import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:auto_inject_generator/src/dependency_graph/node.dart';
import 'package:auto_inject_generator/src/dependency_graph/sources/dependency_source.dart';
import 'package:auto_inject_generator/src/parser/annotation_parser.dart';
import 'package:auto_inject_generator/src/parser/parameter_parser.dart';
import 'package:auto_inject_generator/src/parser/utils.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

part 'module_parser_visitor.dart';

class ModuleParserResult {
  final int id;
  final Reference reference;
  final Map<String, List<Node>> dependencies;

  ModuleParserResult({
    required this.id,
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

    final dependencies = <String, List<Node>>{};
    for (final result in visitor.results) {
      for (final env in result.annotation.env) {
        final envList = dependencies.putIfAbsent(env, () => []);

        final source = ModuleSource.fromAnnotation(
          moduleId: id,
          parameter: result.dependencies,
          type: resolveDartType(libraries, result.type),
          annotation: result.annotation,
          access: result.access,
        );
        final node = Node.fromTypes(
          libraries: libraries,
          dependencies: result.dependencies,
          type: result.type,
          source: source,
        );

        envList.add(node);
      }
    }

    return ModuleParserResult(id: id, reference: reference, dependencies: dependencies);
  }
}
