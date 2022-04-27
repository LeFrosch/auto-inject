import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:auto_inject/auto_inject.dart';
import 'package:auto_inject_generator/src/dependency_graph/node.dart';
import 'package:auto_inject_generator/src/dependency_graph/sources/dependency_source.dart';
import 'package:auto_inject_generator/src/parser/annotation_parser.dart';
import 'package:auto_inject_generator/src/parser/class_parser.dart';
import 'package:auto_inject_generator/src/parser/factory/factory_parser.dart';
import 'package:auto_inject_generator/src/parser/module/module_parser.dart';
import 'package:auto_inject_generator/src/parser/utils.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart' hide LibraryBuilder;

part 'library_builder.dart';

class AutoInjectLibraryGenerator implements Generator {
  final String? testEnv;

  static final _allFilesGlob = Glob("lib/**.dart");

  AutoInjectLibraryGenerator({required this.testEnv});

  Future<LibraryElement?> _libraryFromAsset(AssetId assetId, Resolver resolver) async {
    try {
      return await resolver.libraryFor(assetId, allowSyntaxErrors: true);
    } on NonLibraryAssetException catch (_) {
      return null;
    }
  }

  Future<List<LibraryReader>> _readerFromGlob(BuildStep buildStep, Glob glob) {
    return buildStep
        .findAssets(glob)
        .asyncMap((file) async => await _libraryFromAsset(file, buildStep.resolver))
        .where((library) => library != null)
        .map((library) => LibraryReader(library!))
        .toList();
  }

  @override
  FutureOr<String?> generate(LibraryReader _, BuildStep buildStep) async {
    final reader = await _readerFromGlob(buildStep, _allFilesGlob);

    final libraries = await buildStep.resolver.libraries.toList();

    final library = Library((libraryBuilder) {
      final builder = AutoInjectLibraryBuilder(
        libraryBuilder: libraryBuilder,
        reader: reader,
        libraries: libraries,
      );

      builder.parseModules();
      builder.parseClasses();
      builder.parseFactories();

      final testEnv = this.testEnv;
      if (testEnv != null) {
        builder.parseTestModules(testEnv);
        builder.parseGroups();
        builder.buildTestEnv(testEnv);
      } else {
        builder.parseGroups();
      }

      for (final env in builder.dependencies.keys.whereNot((e) => e == testEnv)) {
        builder.buildEnv(env);
      }

      builder.buildInitMethod(testEnv);
    });

    return library.accept(DartEmitter.scoped(useNullSafetySyntax: true)).toString();
  }
}
