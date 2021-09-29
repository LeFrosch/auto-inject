import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_inject_generator/src/parser/utils.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

class ParameterParserResult {
  final DartType type;
  final Reference reference;
  final String? name;
  final bool defaultDependency;

  ParameterParserResult({
    required this.type,
    required this.reference,
    required this.name,
    required this.defaultDependency,
  });

  bool get named => name != null;
}

abstract class ParameterParser {
  static final _defaultDependencies = [
    TypeChecker.fromUrl('getIt:getIt#GetIt'),
  ];

  static ParameterParserResult parse(List<LibraryElement> libraries, ParameterElement parameter) {
    return ParameterParserResult(
      type: parameter.type,
      reference: resolveDartType(libraries, parameter.type),
      name: parameter.isNamed ? parameter.name : null,
      defaultDependency: _defaultDependencies.any((typeChecker) => typeChecker.isExactlyType(parameter.type)),
    );
  }
}
