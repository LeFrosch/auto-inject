part of 'node.dart';

// source: https://en.wikipedia.org/wiki/Topological_sorting
List<Node> topologicalSort(List<Node> nodes) {
  final l = <Node>[];
  final s = nodes.where((node) => node.dependencies.isEmpty).toList();

  if (s.isEmpty) {
    throw UnsupportedError('No node without dependencies found, do you have a circle in your dependencies?');
  }

  while (s.isNotEmpty) {
    final n = s.removeAt(0);
    l.add(n);

    for (final m in nodes.where((node) => node.dependencies.contains(n.nodeId))) {
      if (!m.dependencies.remove(n.nodeId)) {
        throw StateError('Failed to sort dependencies, no edge found from n to m');
      }

      if (m.dependencies.isEmpty) {
        l.add(m);
      }
    }
  }

  if (nodes.any((node) => node.dependencies.isNotEmpty)) {
    throw StateError('Failed to sort dependencies, graph as edges left, do you have a circle in your dependencies?');
  }

  return l;
}
