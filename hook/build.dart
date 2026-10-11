import 'dart:convert';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// The passthrough sources; they compile against the OpenXR headers the
/// openxr plugin vendors (`third_party/openxr/include` of lumina_plugin_openxr).
const passthroughSources = ['src/metaxr_passthrough_c.cpp'];

/// The root of package [name] from the package config above [start] (the
/// hook's output lies under the consuming app's or workspace's `.dart_tool`).
Uri? packageRoot(String name, Uri start) {
  var dir = Directory.fromUri(start);
  while (true) {
    final config = File('${dir.path}${Platform.pathSeparator}.dart_tool${Platform.pathSeparator}package_config.json');
    if (config.existsSync()) {
      final json = jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
      for (final p in (json['packages'] as List).cast<Map<String, dynamic>>()) {
        if (p['name'] == name) {
          final root = config.uri.resolve(p['rootUri'] as String);
          return root.path.endsWith('/') ? root : Uri.parse('$root/');
        }
      }
      return null;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    final targetOS = input.config.code.targetOS;
    final isWindows = targetOS == OS.windows;
    final isAndroid = targetOS == OS.android;
    final openxr = packageRoot('lumina_plugin_openxr', input.outputDirectory) ??
        packageRoot('lumina_plugin_openxr', input.packageRoot);
    if (openxr == null) {
      throw StateError('lumina_plugin_openxr not found in the package config: the passthrough needs its OpenXR headers');
    }
    final headers = Directory.fromUri(openxr.resolve('third_party/openxr/include'));
    if (!headers.existsSync()) throw StateError('OpenXR headers missing: ${headers.path}');

    final builder = CBuilder.library(
      name: 'metaxr_passthrough',
      assetName: 'metaxr_passthrough.dart',
      sources: passthroughSources,
      includes: ['src', headers.path],
      flags: [
        if (isWindows) ...['/std:c++17', '/EHsc', '/utf-8', '/DNOMINMAX'] else ...['-std=c++17', '-fexceptions'],
        if (isAndroid) ...['-llog', '-lc++_static', '-lc++abi'],
      ],
      cppLinkStdLib: isAndroid ? 'c++_static' : null,
    );
    await builder.run(
      input: input,
      output: output,
      logger: Logger('')
        ..level = Level.ALL
        ..onRecord.listen((record) => stderr.writeln(record.message)),
    );
    output.dependencies.add(headers.uri.resolve('openxr/openxr.h'));
  });
}
