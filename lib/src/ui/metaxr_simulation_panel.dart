import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../hand/meta_hand_pose.dart';
import '../passthrough/meta_passthrough_style.dart';

/// Interactive Editor Panel for testing MetaXR features on desktop without a headset.
class MetaXrSimulationPanel extends StatefulWidget {
  final MetaHandPose leftHand;
  final MetaHandPose rightHand;
  final void Function(MetaPassthroughStyle)? onStyleChanged;

  const MetaXrSimulationPanel({
    super.key,
    required this.leftHand,
    required this.rightHand,
    this.onStyleChanged,
  });

  @override
  State<MetaXrSimulationPanel> createState() => _MetaXrSimulationPanelState();
}

class _MetaXrSimulationPanelState extends State<MetaXrSimulationPanel> {
  double _indexPinch = 0.0;
  double _middlePinch = 0.0;
  bool _enableEdges = false;
  final double _edgeContrast = 1.0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MetaXR Simulator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Simulate hand gestures and passthrough styles directly in the editor.'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hand Tracking Gestures (Right Hand)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Index Pinch: ${(_indexPinch * 100).toInt()}%'),
                      if (_indexPinch >= 0.70)
                        const PrimaryBadge(child: Text('PINCHED'))
                      else
                        const OutlineBadge(child: Text('Open')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      PrimaryButton(
                        onPressed: () {
                          setState(() {
                            _indexPinch = 1.0;
                            widget.rightHand.pinch.update(index: 1.0);
                          });
                        },
                        child: const Text('Tap Pinch'),
                      ),
                      const SizedBox(width: 8),
                      OutlineButton(
                        onPressed: () {
                          setState(() {
                            _indexPinch = 0.0;
                            widget.rightHand.pinch.update(index: 0.0);
                          });
                        },
                        child: const Text('Release'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Middle Pinch: ${(_middlePinch * 100).toInt()}%'),
                      if (_middlePinch >= 0.70)
                        const PrimaryBadge(child: Text('PINCHED'))
                      else
                        const OutlineBadge(child: Text('Open')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      PrimaryButton(
                        onPressed: () {
                          setState(() {
                            _middlePinch = 1.0;
                            widget.rightHand.pinch.update(middle: 1.0);
                          });
                        },
                        child: const Text('Tap Pinch'),
                      ),
                      const SizedBox(width: 8),
                      OutlineButton(
                        onPressed: () {
                          setState(() {
                            _middlePinch = 0.0;
                            widget.rightHand.pinch.update(middle: 0.0);
                          });
                        },
                        child: const Text('Release'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Passthrough Edge Styling', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Highlight Surface Edges'),
                      Switch(
                        value: _enableEdges,
                        onChanged: (val) {
                          setState(() {
                            _enableEdges = val;
                            widget.onStyleChanged?.call(
                              MetaPassthroughStyle(
                                enableEdgeRendering: _enableEdges,
                                edgeContrast: _edgeContrast,
                              ),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
