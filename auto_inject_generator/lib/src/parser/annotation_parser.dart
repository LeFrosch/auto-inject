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
  final DartType as;
  final Reference? dispose;

  AnnotationParserResult({
    required this.type,
    required this.env,
    required this.as,
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

    final reader = ConstantReader(annotation);

    AnnotationType? type;
    DartType? as;
    List<String>? env;
    Reference? dispose;

    if (_injectableTypeChecker.isAssignableFrom(element)) {
      type = AnnotationType.injectable;

      final asValue = reader.read('as');
      as = asValue.isNull ? sourceType : asValue.typeValue;

      final envValue = reader.read('env').listValue;
      env = envValue.map((e) => e.toStringValue()!).toList();
    }
    if (_singletonTypeChecker.isAssignableFrom(element)) {
      type = AnnotationType.singleton;

      final disposeValue = reader.read('dispose');
      if (!disposeValue.isNull) {
        dispose = resolveFunctionType(libraries, disposeValue.objectValue.toFunctionValue()!);
      }
    }
    if (_lazySingletonTypeChecker.isAssignableFrom(element)) {
      type = AnnotationType.lazySingleton;
    }

    if (type == null || as == null || env == null) {
      throw UnsupportedError('Annotation is neither a injectable, singleton or a lazy singleton');
    }

    return AnnotationParserResult(
      type: type,
      env: env,
      as: as,
      dispose: dispose,
    );
  }
}
