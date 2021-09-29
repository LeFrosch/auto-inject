import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_inject_generator/src/dependency_graph/sources/dependency_source.dart';
import 'package:auto_inject_generator/src/parser/parameter_parser.dart';
import 'package:auto_inject_generator/src/parser/utils.dart';

part 'topological_sort.dart';

class Node {
  final int nodeId;

  final List<int> dependencies;
  final DependencySource source;

  Node({
    required this.nodeId,
    required this.dependencies,
    required this.source,
  });

  factory Node.fromTypes({
    required List<LibraryElement> libraries,
    required List<ParameterParserResult> dependencies,
    required DartType type,
    required DependencySource source,
  }) {
    return Node(
      source: source,
      nodeId: resolveDartTypeToId(libraries, type),
      dependencies: dependencies
          .where((dependency) => !dependency.defaultDependency)
          .map((dependency) => resolveDartTypeToId(libraries, dependency.type))
          .toList(),
    );
  }
}
