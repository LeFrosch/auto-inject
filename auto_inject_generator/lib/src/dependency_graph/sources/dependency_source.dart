import 'package:auto_inject_generator/src/dependency_graph/sources/get_it_helper.dart';
import 'package:auto_inject_generator/src/parser/annotation_parser.dart';
import 'package:auto_inject_generator/src/parser/module_parser.dart';
import 'package:auto_inject_generator/src/parser/parameter_parser.dart';
import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';

part 'module_source.dart';

abstract class DependencySource {
  final Reference type;

  const DependencySource({required this.type});

  //@protected
  //Expression createInstance(String getItInstanceName) {
  //  final positional = parameter
  //      .where((p) => !p.named)
  //      .map((e) => retrieveFromGetIt(getItInstance: getItInstanceName, type: e.reference));
//
  //  final named = {
  //    for (final param in parameter.where((p) => p.named))
  //      param.name!: retrieveFromGetIt(getItInstance: getItInstanceName, type: param.reference)
  //  };
//
  //  return reference.newInstance(positional, named);
  //}

  Expression create(Reference getItInstance);
}
