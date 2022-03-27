part of 'node.dart';

String _resolveNode(DartEmitter emitter, int id, List<Node> nodes) {
  final source = nodes.firstWhere((node) => node.nodeId == id).source;

  return source.type.accept(emitter).toString();
}

// source: https://en.wikipedia.org/wiki/Topological_sorting
List<Node> topologicalSort(List<Node> nodes, String env) {
  // remove unresolvable dependencies
  final removedDependencies = <int, List<int>>{};
  for (final node in nodes) {
    node.dependencies.removeWhere((id) {
      final notFound = nodes.none((node) => node.nodeId == id);

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

  final l = <Node>[];
  final s = nodes.where((node) => node.dependencies.isEmpty).toList();

  if (s.isEmpty) {
    throw UnsupportedError('No node without dependencies found for $env, do you have a circle in your dependencies?');
  }

  while (s.isNotEmpty) {
    final n = s.removeAt(0);
    l.add(n);

    if (n.isLeaf) {
      for (final m in nodes.where((node) => node.dependencies.contains(n.nodeId))) {
        throw UnsupportedError('${_resolveNode(DartEmitter(), m.nodeId, nodes)} as a invalid dependency');
      }

      continue;
    }

    for (final m in nodes.where((node) => node.dependencies.contains(n.nodeId))) {
      if (!m.dependencies.remove(n.nodeId)) {
        throw StateError('Failed to sort dependencies for $env, no edge found from $n to $m');
      }

      if (m.dependencies.isEmpty) {
        s.add(m);
      }
    }
  }

  if (nodes.any((node) => node.dependencies.isNotEmpty)) {
    throw StateError('Could not satisfy all dependency for $env, this maybe due to circles in your dependencies.');
  }

  return l;
}
