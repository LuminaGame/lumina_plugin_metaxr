import 'package:lumina/lumina.dart';
import 'package:lumina_plugin_openxr/runtime.dart';

import 'package:lumina_plugin_metaxr/src/hand/lumina_meta_hand_tracking_component.dart';
import 'package:lumina_plugin_metaxr/src/passthrough/lumina_meta_passthrough_component.dart';
import 'package:lumina_plugin_metaxr/src/passthrough/meta_passthrough_layer.dart';
import 'package:lumina_plugin_metaxr/src/passthrough/meta_passthrough_nodes.dart';
import 'package:lumina_plugin_metaxr/src/passthrough/meta_passthrough_runtime.dart';

/// The plugin's runtime module (`.lmplugin` `"type": "runtime"`): a game
/// with the plugin enabled calls [register] from its generated `main()`,
/// before the game starts.
abstract final class LuminaMetaXrRuntime {
  /// The project settings the game registered with.
  static Map<String, Object?> settings = const {};

  static bool _registered = false;

  /// Whether [register] ran.
  static bool get isRegistered => _registered;

  /// The Blueprint component type of [LuminaMetaPassthroughComponent].
  static const String passthroughComponentType = 'LuminaMetaPassthroughComponent';

  /// The passthrough component from its Blueprint properties: `enabled`
  /// (default true) and `placement` (`underlay`, the default, or `overlay`).
  static LuminaMetaPassthroughComponent passthroughFromProperties(Map<String, dynamic> p) => LuminaMetaPassthroughComponent(
        isEnabled: p['enabled'] != false,
        placement: p['placement'] == 'overlay' ? MetaPassthroughPlacement.overlay : MetaPassthroughPlacement.underlay,
      );

  /// The Blueprint component type of [LuminaMetaHandTrackingComponent].
  static const String handTrackingComponentType = 'LuminaMetaHandTrackingComponent';

  /// A tracked hand from its Blueprint properties: `hand` (`left` or `right`).
  static LuminaMetaHandTrackingComponent handFromProperties(Map<String, dynamic> p) =>
      LuminaMetaHandTrackingComponent(hand: p['hand'] == 'right' ? LuminaXRHand.right : LuminaXRHand.left);

  /// Registers the passthrough Blueprint nodes, the passthrough and hand
  /// tracking components, and the
  /// passthrough part of every immersive session (the openxr plugin's
  /// presenter); idempotent.
  static void register([Map<String, Object?> settings = const {}]) {
    LuminaMetaXrRuntime.settings = Map.unmodifiable(settings);
    if (_registered) return;
    _registered = true;
    MetaPassthroughNodes.register();
    LuminaBlueprintComponents.registerType(passthroughComponentType, passthroughFromProperties);
    LuminaBlueprintComponents.registerType(handTrackingComponentType, handFromProperties);
    MetaPassthroughRuntime.requestExtension();
    OpenXrGamePresenter.extensions.add(MetaPassthroughGameExtension());
  }
}

/// Passthrough in an immersive game: the room under the projection layer,
/// driven by the world's passthrough components (bound as they appear, e.g.
/// once a Blueprint actor spawns).
class MetaPassthroughGameExtension extends OpenXrGameExtension {
  final Map<OpenXrGameSession, MetaPassthroughRuntime> _runtimes = {};

  @override
  void attach(OpenXrGameSession session) {
    final runtime = MetaPassthroughRuntime(openxr: session.backend)..attach(session.session, session.loop);
    _runtimes[session] = runtime;
    final world = session.world;
    if (world != null) runtime.bindWorld(world);
  }

  @override
  void onFrame(OpenXrGameSession session) {
    final runtime = _runtimes[session];
    final world = session.world;
    if (runtime == null || world == null) return;
    for (final actor in world.actors) {
      for (final c in actor.components.whereType<LuminaMetaPassthroughComponent>()) {
        if (c.driver == null) runtime.bind(c);
      }
    }
  }

  @override
  void detach(OpenXrGameSession session) {
    final runtime = _runtimes.remove(session);
    if (runtime == null) return;
    runtime.detach(session.session, session.loop);
    runtime.dispose();
  }
}
