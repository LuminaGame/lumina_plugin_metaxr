/// Target Meta Quest device hardware models.
enum MetaQuestDeviceModel {
  quest2('Meta Quest 2'),
  questPro('Meta Quest Pro'),
  quest3('Meta Quest 3'),
  quest3S('Meta Quest 3S');

  final String displayName;
  const MetaQuestDeviceModel(this.displayName);

  /// Whether the device supports full color high-resolution passthrough.
  bool get hasColorPassthrough {
    switch (this) {
      case MetaQuestDeviceModel.quest2:
        return false; // Monochrome IR passthrough
      case MetaQuestDeviceModel.questPro:
      case MetaQuestDeviceModel.quest3:
      case MetaQuestDeviceModel.quest3S:
        return true;
    }
  }

  /// Whether the device hardware contains inward-facing eye tracking cameras.
  bool get hasEyeTracking => this == MetaQuestDeviceModel.questPro;

  /// Whether the device hardware contains inward-facing facial expression cameras.
  bool get hasFaceTracking => this == MetaQuestDeviceModel.questPro;

  /// Whether the device has a dedicated active depth sensor for room mesh scanning.
  bool get hasSceneMesh => this == MetaQuestDeviceModel.quest3 || this == MetaQuestDeviceModel.quest3S;

  /// Supported display refresh rates in Hz.
  List<double> get supportedRefreshRates {
    switch (this) {
      case MetaQuestDeviceModel.questPro:
        return const [72.0, 90.0];
      case MetaQuestDeviceModel.quest2:
      case MetaQuestDeviceModel.quest3:
      case MetaQuestDeviceModel.quest3S:
        return const [72.0, 80.0, 90.0, 120.0];
    }
  }
}
