/// Visual styling parameters for Meta Quest mixed reality passthrough.
class MetaPassthroughStyle {
  final double opacity;
  final bool enableEdgeRendering;
  final int edgeColorRgba;
  final double edgeContrast;
  final double brightness;
  final double contrast;
  final double saturation;

  const MetaPassthroughStyle({
    this.opacity = 1.0,
    this.enableEdgeRendering = false,
    this.edgeColorRgba = 0x00FF88FF, // Fluorescent cyan/green edge default
    this.edgeContrast = 1.0,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
  });

  MetaPassthroughStyle copyWith({
    double? opacity,
    bool? enableEdgeRendering,
    int? edgeColorRgba,
    double? edgeContrast,
    double? brightness,
    double? contrast,
    double? saturation,
  }) {
    return MetaPassthroughStyle(
      opacity: opacity ?? this.opacity,
      enableEdgeRendering: enableEdgeRendering ?? this.enableEdgeRendering,
      edgeColorRgba: edgeColorRgba ?? this.edgeColorRgba,
      edgeContrast: edgeContrast ?? this.edgeContrast,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
    );
  }
}
