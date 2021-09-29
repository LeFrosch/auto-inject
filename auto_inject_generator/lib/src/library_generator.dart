import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:auto_inject/auto_inject.dart';
import 'package:auto_inject_generator/src/dependency_graph/node.dart';
import 'package:auto_inject_generator/src/dependency_graph/sources/dependency_source.dart';
import 'package:auto_inject_generator/src/parser/annotation_parser.dart';
import 'package:auto_inject_generator/src/parser/class_parser.dart';
import 'package:auto_inject_generator/src/parser/module_parser.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart' hide LibraryBuilder;

part 'library_builder.dart';

class AutoInjectLibraryGenerator implements Generator {
  static final _allFilesGlob = Glob("**.dart");

  static final _initChecker = TypeChecker.fromRuntime(AutoInjectInit);

  Future<LibraryElement?> _libraryFromAsset(AssetId assetId, Resolver resolver) async {
    try {
      return await resolver.libraryFor(assetId, allowSyntaxErrors: true);
    } on NonLibraryAssetException catch (_) {
      return null;
    }
  }

  @override
  FutureOr<String?> generate(LibraryReader _, BuildStep buildStep) async {
    final reader = await buildStep
        .findAssets(_allFilesGlob)
        .asyncMap((file) async => await _libraryFromAsset(file, buildStep.resolver))
        .where((library) => library != null)
        .map((library) => LibraryReader(library!))
        .toList();

    final libraries = await buildStep.resolver.libraries.toList();

    final library = Library((libraryBuilder) {
      final builder = AutoInjectLibraryBuilder(
        libraryBuilder: libraryBuilder,
        reader: reader,
        libraries: libraries,
      );

      builder.parseModules();
      builder.parseClasses();

      for (final env in builder.dependencies.keys) {
        builder.buildEnv(env);
      }
    });

    return library.accept(DartEmitter.scoped()).toString();
  }
}
