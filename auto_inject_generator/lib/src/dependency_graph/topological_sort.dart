part of 'node.dart';

class _TopologicalNode {
  final List<int> dependencies;
  final int nodeId;
  final bool isLeaf;

  _TopologicalNode(this.dependencies, this.nodeId, this.isLeaf);
}

String _resolveNode(DartEmitter emitter, int id, List<Node> nodes) {
  final source = nodes.firstWhere((node) => node.nodeId == id).source;

  return source.type.accept(emitter).toString();
}

// source: https://en.wikipedia.org/wiki/Topological_sorting
List<Node> topologicalSort(List<Node> nodes, String env) {
  final topologicalNodes = nodes
      .map((e) => _TopologicalNode(
            [
              ...e.dependencies,
              ...nodes.where((n) => e.groupDependencies.any((g) => n.groupIds.contains(g))).map((e) => e.nodeId),
            ],
            e.nodeId,
            e.isLeaf,
          ))
      .toList();

  // remove unresolvable dependencies
  final removedDependencies = <int, List<int>>{};
  for (final node in topologicalNodes) {
    node.dependencies.removeWhere((id) {
      final notFound = topologicalNodes.none((node) => node.nodeId == id);

      if (notFound) {
        removedDependencies.putIfAbsent(node.nodeId, () => []).add(id);
      }
      return notFound;
    });
  }

  if (removedDependencies.isNotEmpty) {
    final emitter = DartEmitter();
    final buffer = StringBuffer();

    buffer.writeln('Found unresolvable dependencies for $env. The following dependencies are effected:\n');

    for (final key in removedDependencies.keys) {
      buffer.writeln('${_resolveNode(emitter, key, nodes)} misses ${removedDependencies[key]?.length} dependencies');
    }

    log.warning(buffer);
  }

  final l = <_TopologicalNode>[];
  final s = topologicalNodes.where((e) => e.dependencies.isEmpty).toList();

  if (s.isEmpty) {
    throw UnsupportedError('No node without dependencies found for $env, do you have a circle in your dependencies?');
  }

  while (s.isNotEmpty) {
    final n = s.removeAt(0);
    l.add(n);

    if (n.isLeaf) {
      for (final m in topologicalNodes.where((e) => e.dependencies.contains(n.nodeId))) {
        throw UnsupportedError(
          '${_resolveNode(DartEmitter(), m.nodeId, nodes)} has a invalid dependency (${_resolveNode(DartEmitter(), n.nodeId, nodes)})',
        );
      }

      continue;
    }

    for (final m in topologicalNodes.where((e) => e.dependencies.contains(n.nodeId))) {
      if (!m.dependencies.remove(n.nodeId)) {
        throw StateError('Failed to sort dependencies for $env, no edge found from $n to $m');
      }

      if (m.dependencies.isEmpty) {
        s.add(m);
      }
    }
  }

  if (topologicalNodes.any((e) => e.dependencies.isNotEmpty)) {
    final emitter = DartEmitter();
    final buffer = StringBuffer();

    buffer.writeln(
      'Could not satisfy all dependency for $env this maybe due to circles in your dependencies. The following dependencies are effected:\n',
    );

    for (final node in topologicalNodes.where((e) => e.dependencies.isNotEmpty)) {
      buffer.write('${_resolveNode(emitter, node.nodeId, nodes)} misses: [');
      buffer.write(node.dependencies.map((e) => _resolveNode(emitter, e, nodes)).join(', '));
      buffer.write(']\n');
    }

    throw StateError(buffer.toString());
  }

  return l.map((e) => nodes.firstWhere((n) => n.nodeId == e.nodeId)).toList();
}
