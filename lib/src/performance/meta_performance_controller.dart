import 'package:lumina_plugin_metaxr/src/meta_device.dart';

/// Fixed and Dynamic Foveated Rendering levels on Meta Quest.
enum MetaFoveationLevel {
  none(0),
  low(1),
  medium(2),
  high(3),
  highTop(4);

  final int value;
  const MetaFoveationLevel(this.value);
}

/// Controls Meta Quest display refresh rate and GPU foveated rendering levels.
class MetaPerformanceController {
  MetaQuestDeviceModel deviceModel;
  double _currentRefreshRate = 90.0;
  MetaFoveationLevel _foveationLevel = MetaFoveationLevel.medium;
  bool _useDynamicFoveation = true;

  MetaPerformanceController({
    this.deviceModel = MetaQuestDeviceModel.quest3,
  }) {
    _currentRefreshRate = deviceModel.supportedRefreshRates.contains(90.0)
        ? 90.0
        : deviceModel.supportedRefreshRates.first;
  }

  double get currentRefreshRate => _currentRefreshRate;
  MetaFoveationLevel get foveationLevel => _foveationLevel;
  bool get useDynamicFoveation => _useDynamicFoveation;

  /// Requests a display refresh rate switch (72, 80, 90, 120 Hz).
  bool requestRefreshRate(double rateHz) {
    if (deviceModel.supportedRefreshRates.contains(rateHz)) {
      _currentRefreshRate = rateHz;
      return true;
    }
    return false;
  }

  /// Sets fixed or dynamic foveated rendering level.
  void setFoveationLevel(MetaFoveationLevel level, {bool dynamic = true}) {
    _foveationLevel = level;
    _useDynamicFoveation = dynamic;
  }
}
