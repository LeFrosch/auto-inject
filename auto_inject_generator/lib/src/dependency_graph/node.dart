import 'package:auto_inject_generator/src/dependency_graph/dependency_source.dart';

class Node {
  final int nodeId;
  final Type type;

  final List<int> dependencies;
  final DependencySource source;

  Node({
    required this.nodeId,
    required this.type,
    required this.dependencies,
    required this.source,
  });
}
