import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_plugin_metaxr/runtime.dart';
import 'package:lumina_plugin_openxr/runtime.dart';

import 'support/passthrough_rig.dart';

void main() {
  test('session READY with XR_FB_passthrough listed: the passthrough, then a reconstruction layer, in that order', () {
    final rig = PassthroughRig()..begin();
    expect(rig.recorder.calls.take(2), ['xrCreatePassthroughFB', 'xrCreatePassthroughLayerFB(reconstruction)']);
    expect(rig.runtime.mode, MetaPassthroughMode.layer);
    expect(rig.component.isAvailable, isTrue);
    expect(rig.component.layer.state, MetaPassthroughState.running);
  });

  test('setEnabled(false) pauses the layer, setEnabled(true) resumes it', () {
    final rig = PassthroughRig()..begin();
    rig.recorder.calls.clear();
    rig.component.setEnabled(false);
    expect(rig.recorder.calls, ['xrPassthroughLayerPauseFB']);
    expect(rig.component.layer.state, MetaPassthroughState.paused);
    rig.component.setEnabled(true);
    expect(rig.recorder.calls, ['xrPassthroughLayerPauseFB', 'xrPassthroughLayerResumeFB']);
    expect(rig.component.layer.state, MetaPassthroughState.running);
  });

  test('the session asks for XR_FB_passthrough once the runtime requests it', () {
    MetaPassthroughRuntime.requestExtension();
    expect(OpenXrExtensionRequests.all, contains('XR_FB_passthrough'));
  });
}

