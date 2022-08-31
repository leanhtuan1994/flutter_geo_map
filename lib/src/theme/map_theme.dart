import 'package:flutter/material.dart';

import '../data/map_data_source.dart';
import '../data/map_feature.dart';
import '../drawable/circle_marker.dart';
import '../drawable/marker.dart';
import 'map_highlight_theme.dart';

/// The [VectorMap] theme.
class MapTheme {
  static const Color defaultColor = Color(0xFFE0E0E0);
  static const Color defaultContourColor = Color(0xFF9E9E9E);

  static Color getThemeColor(
      MapDataSource dataSource, MapFeature feature, MapTheme theme) {
    Color? color = theme.getColor(dataSource, feature);

    return color ?? MapTheme.defaultColor;
  }

  /// Gets the feature color.
  static Color getFeatureColor(MapDataSource dataSource, MapFeature feature,
      MapTheme theme, MapHighlightTheme? highlightTheme) {
    Color? color = highlightTheme?.color;
    color ??= theme.getColor(dataSource, feature);

    return color ?? MapTheme.defaultColor;
  }

  /// Gets the feature contour color.
  static Color? getContourColor(
      MapTheme theme, MapHighlightTheme? highlightTheme) {
    Color? color = highlightTheme?.contourColor;
    color ??= theme.contourColor;
    return color;
  }

  /// Builds a [VectorMap]
  MapTheme({
    Color? color,
    this.contourColor,
    this.labelVisibility,
    this.labelStyleBuilder,
    this.backgroundLabelVisibility,
    this.backgroundLabelBuilder,
    this.labelMarginBuilder,
    this.labelBuilder,
    MarkerBuilder? markerBuilder,
  })  : _color = color,
        markerBuilder = markerBuilder ?? CircleMakerBuilder.fixed();

  final Color? _color;
  final Color? contourColor;
  final LabelVisibility? labelVisibility;
  final LabelStyleBuilder? labelStyleBuilder;
  final MarkerBuilder markerBuilder;
  final BackgroundLabelVisibility? backgroundLabelVisibility;
  final BackgroundLabelBuilder? backgroundLabelBuilder;
  final LabelMarginBuilder? labelMarginBuilder;
  final LabelBuilder? labelBuilder;

  /// Indicates whether the theme has any value set.
  bool hasValue() {
    return _color != null || contourColor != null || labelVisibility != null;
  }

  /// Gets the feature color.
  Color? getColor(MapDataSource dataSource, MapFeature feature) => _color;
}

/// Defines the visibility of a [MapFeature]
typedef LabelVisibility = bool Function(MapFeature feature);

/// The label style builder.
typedef LabelStyleBuilder = TextStyle Function(
  MapFeature feature,
  Color featureColor,
  Color labelColor,
);

typedef LabelBuilder = String? Function(MapFeature feature);

/// Defines the label background visibility of a [MapFeature]
typedef BackgroundLabelVisibility = bool Function(MapFeature feature);

typedef LabelMarginBuilder = Offset Function(MapFeature feature);

/// Defines the label background style visibility of a [MapFeature]
typedef BackgroundLabelBuilder = BackgroundLabelStyle Function(
  MapFeature feature,
);

class BackgroundLabelStyle {
  final Color color;
  final Radius radius;
  final double horizontalPadding;
  final double verticalPadding;
  final double arrowRadius;

  const BackgroundLabelStyle({
    this.color = Colors.white,
    this.radius = const Radius.circular(24),
    this.horizontalPadding = 8,
    this.verticalPadding = 4,
    this.arrowRadius = 8,
  });
}
