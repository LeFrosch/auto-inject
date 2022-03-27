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

  ParameterParserResult({
    required this.type,
    required this.reference,
    required this.name,
    required this.named,
    required this.defaultDependency,
    required this.assisted,
  });
}

abstract class ParameterParser {
  static final _assistedAnnotation = TypeChecker.fromRuntime(Assisted);

  static final _defaultDependencies = [
    TypeChecker.fromUrl('getIt:getIt#GetIt'),
  ];

  static ParameterParserResult parse(List<LibraryElement> libraries, ParameterElement parameter) {
    return ParameterParserResult(
      type: parameter.type,
      reference: resolveDartType(libraries, parameter.type),
      name: parameter.name,
      named: parameter.isNamed,
      defaultDependency: _defaultDependencies.any((typeChecker) => typeChecker.isExactlyType(parameter.type)),
      assisted: _assistedAnnotation.hasAnnotationOf(parameter, throwOnUnresolved: false),
    );
  }
}
