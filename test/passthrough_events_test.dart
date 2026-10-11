import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_plugin_metaxr/runtime.dart';
import 'package:lumina_plugin_openxr/runtime.dart';

import 'support/passthrough_rig.dart';

void main() {
  OpenXrRuntimeEvent stateChanged(int flags) => OpenXrRuntimeEvent.fromNative(
      kind: 0, structureType: MetaPassthroughEvents.stateChangedType, payload: flags);

  test('PASSTHROUGH_STATE_CHANGED with NON_RECOVERABLE_ERROR: the layer fails and the component reports it', () {
    final rig = PassthroughRig()..begin();
    for (final l in rig.session.eventListeners) {
      l(stateChanged(MetaPassthroughEvents.nonRecoverableError));
    }
    expect(rig.component.layer.state, MetaPassthroughState.failed);
    expect(rig.component.hasFailed, isTrue);
    rig.pacer.tick();
    expect(rig.sim.submittedLayers, ['projection'], reason: 'a failed layer is not submitted');
    rig.recorder.calls.clear();
    rig.component.setEnabled(false);
    rig.component.setEnabled(true);
    expect(rig.recorder.calls, isEmpty, reason: 'a failed passthrough is not driven');
  });

  test('a recoverable error, then RESTORED: recovering, then running again', () {
    final rig = PassthroughRig()..begin();
    rig.runtime.onEvent(stateChanged(MetaPassthroughEvents.recoverableError));
    expect(rig.component.layer.state, MetaPassthroughState.recovering);
    rig.runtime.onEvent(stateChanged(MetaPassthroughEvents.restoredError));
    expect(rig.component.layer.state, MetaPassthroughState.running);
  });
}
