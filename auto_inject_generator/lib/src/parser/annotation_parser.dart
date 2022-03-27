import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:auto_inject/auto_inject.dart';
import 'package:auto_inject_generator/src/parser/utils.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

enum AnnotationType { injectable, assisted, singleton, lazySingleton }

class DisposeResult {
  final bool topLevel;
  final Reference method;

  DisposeResult({required this.topLevel, required this.method});
}

class AnnotationParserResult {
  final AnnotationType type;
  final List<String> env;
  final DartType as;
  final DisposeResult? dispose;

  AnnotationParserResult({
    required this.type,
    required this.env,
    required this.as,
    this.dispose,
  });
}

abstract class AnnotationParser {
  static final classAnnotation = _injectableTypeChecker;

  static final _injectableTypeChecker = TypeChecker.fromRuntime(Injectable);
  static final _assistedInjectableTypeChecker = TypeChecker.fromRuntime(AssistedInjectable);
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
    DisposeResult? dispose;

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
        dispose = DisposeResult(
          method: resolveFunctionType(libraries, disposeValue.objectValue.toFunctionValue()!),
          topLevel: true,
        );
      }

      if (dispose == null) {
        final visitor = _DisposeMethodVisitor();
        sourceType.element?.visitChildren(visitor);

        final result = visitor.disposeMethod;
        if (result != null) {
          dispose = DisposeResult(
            method: resolveFunctionType(libraries, result),
            topLevel: false,
          );
        }
      }
    }
    if (_lazySingletonTypeChecker.isAssignableFrom(element)) {
      type = AnnotationType.lazySingleton;
    }
    if (_assistedInjectableTypeChecker.isAssignableFrom(element)) {
      type = AnnotationType.assisted;
    }

    if (type == null || as == null || env == null) {
      throw UnsupportedError('Annotation is neither a injectable, assisted injectable, singleton or a lazy singleton');
    }

    return AnnotationParserResult(
      type: type,
      env: env,
      as: as,
      dispose: dispose,
    );
  }
}

class _DisposeMethodVisitor extends SimpleElementVisitor<void> {
  static final _disposeAnnotationChecker = TypeChecker.fromRuntime(DisposeMethod);

  MethodElement? disposeMethod;

  @override
  void visitMethodElement(MethodElement element) {
    if (_disposeAnnotationChecker.hasAnnotationOf(element)) {
      disposeMethod = element;
    }
  }
}
