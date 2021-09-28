import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_inject/auto_inject.dart';
import 'package:auto_inject_generator/src/parser/utils.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

enum AnnotationType { injectable, singleton, lazySingleton }

class AnnotationParserResult {
  final AnnotationType type;
  final List<String> env;
  final Reference reference;
  final Reference? dispose;

  AnnotationParserResult({
    required this.type,
    required this.env,
    required this.reference,
    this.dispose,
  });
}

abstract class AnnotationParser {
  static final annotationTypeChecker = _injectableTypeChecker;

  static final _injectableTypeChecker = TypeChecker.fromRuntime(Injectable);
  static final _singletonTypeChecker = TypeChecker.fromRuntime(Singleton);
  static final _lazySingletonTypeChecker = TypeChecker.fromRuntime(LazySingleton);

  static AnnotationParserResult parse(List<LibraryElement> libraries, DartType sourceType, DartObject annotation) {
    final element = annotation.type?.element;
    if (element == null) {
      throw UnsupportedError('Could not get annotation type element');
    }

    AnnotationType? type;
    Reference? reference;
    List<String>? env;
    Reference? dispose;

    if (_injectableTypeChecker.isAssignableFrom(element)) {
      type = AnnotationType.injectable;

      final referenceValue = annotation.getField('as')?.toTypeValue();
      reference = resolveDartType(libraries, referenceValue ?? sourceType);

      final envValue = annotation.getField('env')?.toListValue();
      env = envValue?.map((e) => e.toStringValue()!).toList() ?? const [];
    }
    if (_singletonTypeChecker.isAssignableFrom(element)) {
      type = AnnotationType.singleton;

      final disposeValue = annotation.getField('dispose')?.toFunctionValue();
      if (disposeValue != null) {
        dispose = resolveFunctionType(libraries, disposeValue);
      }
    }
    if (_lazySingletonTypeChecker.isAssignableFrom(element)) {
      type = AnnotationType.lazySingleton;
    }

    if (type == null || reference == null || env == null) {
      throw UnsupportedError('Annotation is neither a injectable, singleton or a lazy singleton');
    }

    return AnnotationParserResult(
      type: type,
      env: env,
      reference: reference,
      dispose: dispose,
    );
  }
}
