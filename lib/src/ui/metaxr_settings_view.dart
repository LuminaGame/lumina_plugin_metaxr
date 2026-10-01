import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../meta_device.dart';
import '../performance/meta_performance_controller.dart';

/// Settings panel for MetaXR features and Quest target devices.
class MetaXrSettingsView extends StatefulWidget {
  final MetaPerformanceController performance;

  const MetaXrSettingsView({super.key, required this.performance});

  @override
  State<MetaXrSettingsView> createState() => _MetaXrSettingsViewState();
}

class _MetaXrSettingsViewState extends State<MetaXrSettingsView> {
  late MetaQuestDeviceModel _selectedDevice;
  late double _selectedRate;
  late MetaFoveationLevel _selectedFoveation;

  @override
  void initState() {
    super.initState();
    _selectedDevice = widget.performance.deviceModel;
    _selectedRate = widget.performance.currentRefreshRate;
    _selectedFoveation = widget.performance.foveationLevel;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Meta Quest Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Configure Meta-OpenXR-SDK capabilities, passthrough, and device profiles.'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Target Quest Device', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final dev in MetaQuestDeviceModel.values)
                        dev == _selectedDevice
                            ? PrimaryButton(
                                onPressed: () {},
                                child: Text(dev.displayName),
                              )
                            : OutlineButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedDevice = dev;
                                    widget.performance.deviceModel = dev;
                                    _selectedRate = dev.supportedRefreshRates.contains(_selectedRate)
                                        ? _selectedRate
                                        : dev.supportedRefreshRates.first;
                                    widget.performance.requestRefreshRate(_selectedRate);
                                  });
                                },
                                child: Text(dev.displayName),
                              ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Color Passthrough: '),
                      _selectedDevice.hasColorPassthrough
                          ? const PrimaryBadge(child: Text('Supported'))
                          : const OutlineBadge(child: Text('Monochrome IR')),
                      const SizedBox(width: 12),
                      const Text('Face & Eye Tracking: '),
                      _selectedDevice.hasFaceTracking
                          ? const PrimaryBadge(child: Text('Supported'))
                          : const OutlineBadge(child: Text('Unsupported')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Display & GPU Performance', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  const Text('Refresh Rate:'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final rate in _selectedDevice.supportedRefreshRates)
                        rate == _selectedRate
                            ? PrimaryButton(
                                onPressed: () {},
                                child: Text('${rate.toInt()} Hz'),
                              )
                            : OutlineButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedRate = rate;
                                    widget.performance.requestRefreshRate(rate);
                                  });
                                },
                                child: Text('${rate.toInt()} Hz'),
                              ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Foveated Rendering Level:'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final fov in MetaFoveationLevel.values)
                        fov == _selectedFoveation
                            ? PrimaryButton(
                                onPressed: () {},
                                child: Text(fov.name),
                              )
                            : OutlineButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedFoveation = fov;
                                    widget.performance.setFoveationLevel(fov);
                                  });
                                },
                                child: Text(fov.name),
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
