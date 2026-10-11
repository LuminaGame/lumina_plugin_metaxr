// MetaXR passthrough smoke: the simulated headset stands in for the room
// camera with a rendered room (a table, a chair, a sink on concrete slabs
// from test-assets), styled like XrPassthroughStyleFB as the style changes
// over time (opacity, edges, saturation, contrast); the game (a barrel) is
// rendered by the headset renderer with a transparent clear, and its eye
// images are blended over the room with their alpha, as the runtime blends
// an alpha-flagged projection layer over a passthrough underlay.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_filament/filament.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_plugin_metaxr/runtime.dart';
import 'package:lumina_plugin_openxr/runtime.dart';
import 'package:lumina_smoke/lumina_smoke.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

const _name = 'MetaXR passthrough smoke a barrel over the simulated room as the passthrough style changes';

void main() {
  const eyeWidth = 768;
  const eyeHeight = 768;
  const fps = 30.0;

  test(_name, () {
    SmokeArtifacts.resetRecordedAssets();
    final offscreen = ExternalVulkanOffscreen.create(
        width: eyeWidth, height: eyeHeight, layers: 2, multiview: true, srgb: true);
    if (offscreen == null) return markTestSkipped('no Vulkan device');
    final engine = FilamentEngine.createOnExternalVulkan(offscreen.context,
        config: const EngineConfig(stereoscopicType: StereoscopicType.multiview, stereoscopicEyeCount: 2));
    if (engine == null || !engine.isStereoSupported(StereoscopicType.multiview)) {
      engine?.dispose();
      offscreen.dispose();
      return markTestSkipped('no multiview engine');
    }
    final swapChain = FilamentSwapChain.external(engine, offscreen.provider)!;
    final renderer = OpenXrFilamentRenderer.onSwapChain(engine, swapChain, width: eyeWidth, height: eyeHeight)
      ..setClearColor(0.04, 0.05, 0.09);
    final room = engine.createScene();
    final game = renderer.scene;
    final lights = <int>[];
    for (final scene in [room, game]) {
      final sun = engine.createEntity();
      LightBuilder(LightType.directional)
        ..color(1.0, 0.97, 0.92)
        ..intensity(100000)
        ..direction(0.4, -1.0, -0.6)
        ..build(engine, sun);
      scene.addEntity(sun);
      lights.add(sun);
    }
    final materials = FilamentMaterialProvider.ubershader(engine);
    final loader = FilamentAssetLoader.create(engine: engine, materialProvider: materials);
    final assets = <(FilamentAsset, FilamentScene)>[];
    void place(String file, FilamentScene scene, vm.Vector3 at, double size, {double yaw = 0}) {
      final path = '${SmokeArtifacts.testAssetsDir.path}/$file';
      SmokeArtifacts.recordAsset(path);
      final asset = loader.createAsset(File(path).readAsBytesSync())!;
      final resources = FilamentResourceLoader.create(engine: engine)..registerDefaultProviders(engine);
      resources.loadResources(asset);
      resources.dispose();
      asset.addToScene(scene);
      final box = asset.getBoundingBox();
      final scale = size / (box.max - box.min).length;
      final c = box.center;
      final m = vm.Matrix4.translation(at)
        ..rotateY(yaw)
        ..multiply(vm.Matrix4.diagonal3Values(scale, scale, scale))
        ..multiply(vm.Matrix4.translationValues(-c.x, -box.min.y, -c.z));
      FilamentTransformManager(engine).setTransform(asset.rootEntity, m.storage);
      assets.add((asset, scene));
    }

    // The room the camera would see.
    place('structures/Concrete_slabs/concrete_slabs_6x6.glb', room, vm.Vector3(0, 0, -2), 6);
    place('Props/Foldable Table/foldable_table.glb', room, vm.Vector3(-0.2, 0, -2.2), 1.6, yaw: 0.3);
    place('Props/Chair/chair.glb', room, vm.Vector3(0.9, 0, -1.8), 1.1, yaw: -0.8);
    place('Props/Freestanding Sink/freestanding_sink.glb', room, vm.Vector3(-1.4, 0, -2.6), 1.3, yaw: 0.6);
    // The game.
    place('Props/Barrels/fuel_barrel_red.glb', game, vm.Vector3(0.15, 0, -1.4), 1.0);

    final simulator = SimulatedOpenXrBackend()
      ..offeredExtensions.add(MetaOpenXrExtensions.passthrough)
      ..headPosition = vm.Vector3(0, 1.6, 0)
      ..initialize();
    final session = OpenXrSession(backend: simulator);
    final pacer = OpenXrSimulatedPacer(simulator, period: Duration(microseconds: (1e6 / fps / 2).round()), automatic: false);
    final loop = OpenXrFrameLoop(pacer: pacer, renderer: renderer);
    final recorder = MetaPassthroughRecorder();
    final component = LuminaMetaPassthroughComponent();
    final runtime = MetaPassthroughRuntime(openxr: simulator, passthrough: recorder)
      ..bind(component)
      ..attach(session, loop);
    session.beginSession();
    loop.start();

    Uint8List renderPass(FilamentScene scene, {required bool transparent}) {
      renderer.view.scene = scene;
      renderer.transparentBackground = transparent;
      final before = loop.renderedFrames;
      for (var attempt = 0; attempt < 200 && loop.renderedFrames == before; attempt++) {
        pacer.tick();
        if (loop.renderedFrames == before) sleep(const Duration(milliseconds: 4));
      }
      expect(loop.renderedFrames, before + 1);
      engine.flushAndWait();
      final image = offscreen.events.lastWhere((e) => e.present).index;
      return Uint8List.fromList([...offscreen.readPixels(image, layer: 0)!, ...offscreen.readPixels(image, layer: 1)!]);
    }

    final frames = SmokeArtifacts.framesForSeconds(fps);
    final pngs = <Uint8List>[];
    try {
      expect(runtime.mode, MetaPassthroughMode.layer);
      for (var f = 0; f < frames; f++) {
        final t = f / fps;
        simulator.setHeadLookAngles(0.3 * math.sin(t * 0.6), -0.25 + 0.08 * math.sin(t * 1.1));
        // The style walks through opacity, edges, saturation and contrast.
        final phase = (t / 2.5).floor() % 4;
        component.setStyle(switch (phase) {
          0 => const MetaPassthroughStyle(),
          1 => MetaPassthroughStyle(opacity: 0.55 + 0.45 * math.cos(t * 2)),
          2 => const MetaPassthroughStyle(enableEdgeRendering: true, edgeColorRgba: 0x00FFFFFF, saturation: 0.2),
          _ => MetaPassthroughStyle(contrast: 1.5, brightness: 10 * math.sin(t * 3), saturation: 1.6),
        });
        final feed = renderPass(room, transparent: false);
        final eye = renderPass(game, transparent: true);
        final style = recorder.styles.last;
        final styled = Uint8List(feed.length);
        final half = feed.length ~/ 2;
        styled.setRange(0, half, MetaPassthroughSimulator.styleFeed(Uint8List.sublistView(feed, 0, half), eyeWidth, eyeHeight, style));
        styled.setRange(half, feed.length,
            MetaPassthroughSimulator.styleFeed(Uint8List.sublistView(feed, half), eyeWidth, eyeHeight, style));
        final out = MetaPassthroughSimulator.composite(eye, styled);
        pngs.add(SmokeArtifacts.encodePng(eyeWidth * 2, eyeHeight,
            _sideBySide(Uint8List.sublistView(out, 0, half), Uint8List.sublistView(out, half), eyeWidth, eyeHeight)));
      }
      expect(simulator.submittedLayers, ['passthrough', 'projection']);
      SmokeArtifacts.saveVideoFromPngFrames(_name, pngs, fps: fps);
      SmokeArtifacts.saveScreenshot(_name, pngs[(fps * 6).round()]);
      SmokeArtifacts.annotate(_name, {
        'metrics': {
          'frames': frames,
          'style_calls': recorder.styles.length,
          'submitted_layers': simulator.submittedLayers.join(', '),
          'projection_flags': simulator.compositions.last.projectionFlags,
          'gpu': engine.gpuName,
        },
      });
      expect(pngs.first, isNot(equals(pngs.last)));
    } finally {
      loop.stop();
      engine.flushAndWait();
      runtime.dispose();
      renderer.view.scene = game;
      for (final (a, scene) in assets) {
        a.removeFromScene(scene);
        loader.destroyAsset(a);
      }
      loader.dispose();
      materials.dispose();
      for (final (i, scene) in [room, game].indexed) {
        scene.removeEntity(lights[i]);
        engine.destroyEntity(lights[i]);
      }
      room.dispose();
      renderer.dispose();
      swapChain.dispose();
      engine.dispose();
      offscreen.dispose();
      SmokeArtifacts.resetRecordedAssets();
    }
  }, timeout: const Timeout(Duration(minutes: 8)));
}

Uint8List _sideBySide(Uint8List left, Uint8List right, int w, int h) {
  final out = Uint8List(w * 2 * h * 4);
  for (var y = 0; y < h; y++) {
    out.setRange(y * w * 8, y * w * 8 + w * 4, left, y * w * 4);
    out.setRange(y * w * 8 + w * 4, (y + 1) * w * 8, right, y * w * 4);
  }
  return out;
}
