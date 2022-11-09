import 'package:flutter/material.dart';
import 'map_theme.dart';

/// The theme for highlights.
///
/// This theme is activated by hover or external components like a legend.
class MapHighlightTheme {
  /// Builds a [MapHighlightTheme]
  MapHighlightTheme({
    this.color,
    this.contourColor,
    this.labelVisibility,
    this.labelStyleBuilder,
    this.overlayContour = false,
    this.backgroundLabelBuilder,
    this.backgroundLabelVisibility,
    this.labelMarginBuilder,
    this.labelBuilder,
    this.modifiedCenter = true,
    this.markerVisibility,
  });

  final Color? color;
  final Color? contourColor;

  final LabelVisibility? labelVisibility;
  final LabelStyleBuilder? labelStyleBuilder;

  final BackgroundLabelVisibility? backgroundLabelVisibility;
  final BackgroundLabelBuilder? backgroundLabelBuilder;
  final bool modifiedCenter;

  final MarkerVisibility? markerVisibility;

  LabelMarginBuilder? labelMarginBuilder;

  LabelBuilder? labelBuilder;

  final bool overlayContour;

  /// Indicates whether the theme has any value set.
  bool get hasValue {
    return color != null || contourColor != null || labelVisibility != null;
  }
}
