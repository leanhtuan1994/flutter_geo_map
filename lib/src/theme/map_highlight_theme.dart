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
  });

  final Color? color;
  final Color? contourColor;

  final LabelVisibility? labelVisibility;
  final LabelStyleBuilder? labelStyleBuilder;

  final bool overlayContour;

  /// Indicates whether the theme has any value set.
  bool get hasValue {
    return color != null || contourColor != null || labelVisibility != null;
  }
}
