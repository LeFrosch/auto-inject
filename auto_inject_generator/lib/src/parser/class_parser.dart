import 'package:analyzer/dart/element/element.dart';
import 'package:auto_inject_generator/src/dependency_graph/node.dart';
import 'package:auto_inject_generator/src/dependency_graph/sources/dependency_source.dart';
import 'package:auto_inject_generator/src/parser/annotation_parser.dart';
import 'package:auto_inject_generator/src/parser/parameter_parser.dart';
import 'package:auto_inject_generator/src/parser/utils.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

ClassElement _parseClassElement(List<LibraryElement> libraries, AnnotatedElement annotation) {
  final classElement = annotation.element;
  if (classElement is! ClassElement) {
    throw UnsupportedError('${classElement.name} is not a Class, only annotate classes with a inject annotation');
  }
  if (classElement.isAbstract) {
    throw UnsupportedError('${classElement.name} is abstract, only annotate normal classes with a inject annotation');
  }

  final constructor = classElement.unnamedConstructor;
  if (constructor == null) {
    throw UnsupportedError(
      '${classElement.name} has no default constructor, classes annotated with a inject annotation must have a default constructor',
    );
  }

  return classElement;
}

ConstructorElement _parseConstructor(ClassElement element) {
  final constructor = element.unnamedConstructor;
  if (constructor == null) {
    throw UnsupportedError(
      '${element.name} has no default constructor, classes annotated with a inject annotation must have a default constructor',
    );
  }

  return constructor;
}

abstract class ClassParser {
  static Map<String, Node> parse(List<LibraryElement> libraries, AnnotatedElement annotation) {
    final classElement = _parseClassElement(libraries, annotation);
    final constructor = _parseConstructor(classElement);

    final annotationResult = AnnotationParser.parse(
      libraries,
      classElement.thisType,
      annotation.annotation.objectValue,
    );

    final parameter = constructor.parameters.map((dependency) => ParameterParser.parse(libraries, dependency)).toList();
    if (parameter.any((e) => e.assisted)) {
      throw UnsupportedError('Assisted arguments are only support with assisted injection');
    }

    final type = annotationResult.as;

    final dependencies = <String, Node>{};
    for (final env in annotationResult.env) {
      final source = ClassSource.fromAnnotation(
        parameter: parameter,
        type: resolveDartType(libraries, type),
        classType: resolveDartType(libraries, classElement.thisType),
        annotation: annotationResult,
      );
      final node = Node.fromTypes(
        libraries: libraries,
        dependencies: parameter,
        type: type,
        source: source,
      );

      dependencies[env] = node;
    }

    return dependencies;
  }

  static Node parseAssisted(List<LibraryElement> libraries, AnnotatedElement annotation) {
    final classElement = _parseClassElement(libraries, annotation);
    final constructor = _parseConstructor(classElement);

    final annotationResult = AnnotationParser.parse(
      libraries,
      classElement.thisType,
      annotation.annotation.objectValue,
    );

    final parameter = constructor.parameters.map((dependency) => ParameterParser.parse(libraries, dependency)).toList();
    if (!parameter.any((e) => e.assisted)) {
      log.warning('${classElement.name} has no assisted arguments, assisted injection is unnecessary');
    }

    return Node.fromTypes(
      libraries: libraries,
      dependencies: parameter,
      type: annotationResult.as,
      source: null,
    );
  }
}
