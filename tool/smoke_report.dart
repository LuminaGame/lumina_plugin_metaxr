// Runs lumina_plugin_metaxr's smoke tests (desktop GPU, the simulated headset)
// and writes `build/smoke_report.html`, linking the PNGs and videos in
// `build/smoke_artifacts/vulkan/`.
//
//   dart run tool/smoke_report.dart test/smoke/metaxr_passthrough_smoke_test.dart --no-dashboard
//
// The runner, the report and every flag are lumina_smoke's
// (`package:lumina_smoke/report.dart`).
import 'package:lumina_smoke/report.dart';

/// The plugin's report configuration.
const SmokeReportConfig metaXrSmokeConfig = SmokeReportConfig(
  title: 'MetaXR Plugin Test Report',
  tag: 'lumina_plugin_metaxr',
  dashboardTitle: 'MetaXR Smoke Tests',
  categories: TestCategories([
    ('passthrough', ['passthrough']),
  ]),
  categoryNote: 'Every PNG and video is linked from build/smoke_artifacts/, not embedded.',
  failingCategoriesFirst: true,
  backends: [
    SmokeBackend('vulkan', environment: {'FILAMENT_SMOKE_BACKEND': 'vulkan'}),
  ],
);

Future<void> main(List<String> args) => smokeReportMain(args, metaXrSmokeConfig);
