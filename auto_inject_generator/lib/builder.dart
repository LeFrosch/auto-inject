import 'package:auto_inject_generator/src/library_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

Builder autoInjectBuilder(BuilderOptions options) {
  return LibraryBuilder(
    AutoInjectLibraryGenerator(),
    generatedExtension: '.auto.dart',
  );
}
