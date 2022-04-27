import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_inject/auto_inject.dart';
import 'package:auto_inject_generator/src/parser/utils.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

class ParameterParserResult {
  final DartType type;
  final Reference reference;
  final String name;
  final bool named;
  final bool defaultDependency;
  final bool assisted;
  final bool group;

  ParameterParserResult({
    required this.type,
    required this.reference,
    required this.name,
    required this.named,
    required this.defaultDependency,
    required this.assisted,
    required this.group,
  });
}

abstract class ParameterParser {
  static final _assistedAnnotation = TypeChecker.fromRuntime(AssistedField);
  static final _groupAnnotation = TypeChecker.fromRuntime(GroupField);
  static final _iterableAnnotation = TypeChecker.fromRuntime(Iterable);

  static final _defaultDependencies = [
    TypeChecker.fromUrl('getIt:getIt#GetIt'),
  ];

  static ParameterParserResult parse(List<LibraryElement> libraries, ParameterElement parameter) {
    if (_groupAnnotation.hasAnnotationOf(parameter, throwOnUnresolved: false)) {
      final type = parameter.type;

      if (!_iterableAnnotation.isExactlyType(type) || type is! ParameterizedType) {
        throw UnsupportedError('Groups must be an Iterable<T>');
      }

      final groupType = type.typeArguments[0];

      return ParameterParserResult(
        type: groupType,
        reference: resolveDartType(libraries, type),
        name: parameter.name,
        named: parameter.isNamed,
        defaultDependency: false,
        assisted: false,
        group: true,
      );
    } else {
      return ParameterParserResult(
        type: parameter.type,
        reference: resolveDartType(libraries, parameter.type),
        name: parameter.name,
        named: parameter.isNamed,
        defaultDependency: _defaultDependencies.any((typeChecker) => typeChecker.isExactlyType(parameter.type)),
        assisted: _assistedAnnotation.hasAnnotationOf(parameter, throwOnUnresolved: false),
        group: false,
      );
    }
  }
}
