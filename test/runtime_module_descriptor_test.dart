import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/lumina.dart';
import 'package:lumina_plugin_metaxr/runtime.dart';

/// The descriptor's game side: the runtime module a game's `main()`
/// registers, and what the plugin adds to a Quest build's manifest.
void main() {
  test('passthrough is required once a level uses the component; hand tracking only when used', () async {
    final descriptor = await PluginRepository(roots: const []).load(File('lumina_plugin_metaxr.lmplugin'));
    expect(descriptor.runtimeModules.single.registrationClass, 'LuminaMetaXrRuntime');
    final android = descriptor.android!;
    final passthrough = android.usesFeatures.firstWhere((f) => f.name == 'com.oculus.feature.PASSTHROUGH');
    expect(passthrough.resolvedFor(const {'LuminaMetaPassthroughComponent'}).required, isTrue);
    expect(passthrough.resolvedFor(const {}).required, isFalse);
    expect(android.usesFeatures.firstWhere((f) => f.name == 'oculus.software.handtracking').whenUsed, 'LuminaMetaHandTrackingComponent');
    expect(android.permissions.single.whenUsed, 'LuminaMetaHandTrackingComponent');
    expect(android.metaData.single.value, 'quest3|quest3s|quest2|questpro');
    // The same feature line the passthrough runtime documents.
    expect(passthrough.resolvedFor(const {'LuminaMetaPassthroughComponent'}).toXml().replaceAll(' />', '/>'),
        MetaPassthroughManifest.usesFeature(required: true));
  });

  test('register registers the passthrough nodes once', () {
    LuminaMetaXrRuntime.register(const {'xr': 'quest'});
    LuminaMetaXrRuntime.register(const {'xr': 'quest'});
    expect(LuminaMetaXrRuntime.isRegistered, isTrue);
    expect(LuminaBlueprintFunctionRegistry.entry(MetaPassthroughNodes.setEnabledId), isNotNull);
  });
}
