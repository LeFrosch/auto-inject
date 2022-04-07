import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_inject_generator/src/dependency_graph/sources/dependency_source.dart';
import 'package:auto_inject_generator/src/parser/parameter_parser.dart';
import 'package:auto_inject_generator/src/parser/utils.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

part 'topological_sort.dart';

class NodeGroup extends Equatable {
  final DartType type;
  final int id;

  NodeGroup(this.type, this.id);

  @override
  List<Object?> get props => [id];
}

class Node {
  final int nodeId;
  final List<NodeGroup> groups;

  final List<int> dependencies;
  final List<int> groupDependencies;
  final DependencySource source;

  Node({
    required this.nodeId,
    required this.groups,
    required this.dependencies,
    required this.groupDependencies,
    required this.source,
  });

  bool get isLeaf => !source.canSupply;

  List<int> get groupIds => groups.map((e) => e.id).toList();

  factory Node.fromTypes({
    required List<LibraryElement> libraries,
    required List<ParameterParserResult> parameters,
    required List<DartType> groups,
    required DartType type,
    required DependencySource source,
  }) {
    return Node(
      source: source,
      nodeId: resolveDartTypeToId(libraries, type),
      groups: groups.map((e) => NodeGroup(e, resolveDartTypeToId(libraries, e))).toList(),
      dependencies: parameters
          .whereNot((e) => e.assisted || e.group || e.defaultDependency)
          .map((e) => resolveDartTypeToId(libraries, e.type))
          .toList(),
      groupDependencies: parameters.where((e) => e.group).map((e) => resolveDartTypeToId(libraries, e.type)).toList(),
    );
  }
}
