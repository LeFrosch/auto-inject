import 'package:auto_inject_generator/src/dependency_graph/sources/get_it_helper.dart';
import 'package:auto_inject_generator/src/parser/annotation_parser.dart';
import 'package:auto_inject_generator/src/parser/module_parser.dart';
import 'package:auto_inject_generator/src/parser/parameter_parser.dart';
import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';

part 'class_source.dart';
part 'module_source.dart';

abstract class DependencySource {
  final Reference type;

  const DependencySource({required this.type});

  Expression create(Reference getItInstance);
}
