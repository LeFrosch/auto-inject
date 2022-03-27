import 'package:auto_inject_generator/src/dependency_graph/sources/get_it_helper.dart';
import 'package:auto_inject_generator/src/parser/annotation_parser.dart';
import 'package:auto_inject_generator/src/parser/parameter_parser.dart';
import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';

import '../../parser/module/module_parser.dart';
import '../node.dart';

part 'class_source.dart';
part 'module_source.dart';

mixin AssistedDependency on DependencySource {
  @override
  bool get canSupply => false;
}

abstract class DependencySource {
  final Reference type;

  const DependencySource({required this.type});

  bool get canSupply => true;

  Expression create(Reference getItInstance);

  Iterable<Spec> createGlobal(Iterable<Node> dependencies) => const [];
}
