import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';

bool _isCoreDartType(Element? element) {
  return element?.source?.fullName == 'dart:core';
}

String? resolveImport(List<LibraryElement> libraries, Element? element) {
  // return early if source is null or element is a core type
  if (element?.source == null || _isCoreDartType(element)) {
    return null;
  }

  for (final lib in libraries) {
    if (!_isCoreDartType(lib) && lib.exportNamespace.definedNames.values.contains(element)) {
      return lib.identifier;
    }
  }

  return null;
}

Iterable<Reference> _resolveTypeArguments(List<LibraryElement> libraries, DartType type) sync* {
  if (type is! ParameterizedType) {
    return;
  }

  for (final argumentType in type.typeArguments) {
    yield resolveDartType(libraries, argumentType);
  }
}

int resolveDartTypeToId(List<LibraryElement> libraries, DartType type) {
  final symbol = resolveDartTypeName(type);
  final url = resolveImport(libraries, type.element);

  return Object.hash(symbol, url);
}

String resolveDartTypeName(DartType type) => type.element?.name ?? type.getDisplayString(withNullability: false);

Reference resolveDartType(List<LibraryElement> libraries, DartType type) {
  return TypeReference((builder) => builder
    ..symbol = resolveDartTypeName(type)
    ..url = resolveImport(libraries, type.element)
    ..types.addAll(_resolveTypeArguments(libraries, type)));
}

Reference resolveFunctionType(List<LibraryElement> libraries, ExecutableElement executableElement) {
  String displayName = executableElement.displayName;
  Element elementToImport = executableElement;

  final enclosingElement = executableElement.enclosingElement;
  if (enclosingElement is ClassElement) {
    displayName = '${enclosingElement.displayName}.$displayName';
    elementToImport = enclosingElement;
  }

  return TypeReference((builder) => builder
    ..symbol = displayName
    ..url = resolveImport(libraries, elementToImport));
}
