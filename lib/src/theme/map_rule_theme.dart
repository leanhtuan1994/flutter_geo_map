import 'package:flutter/rendering.dart';
import '../data/map_data_source.dart';
import '../data/map_feature.dart';
import '../drawable/marker.dart';
import 'map_theme.dart';

/// Theme for colors by rule.
///
/// The feature color is obtained from the first rule that returns
/// a non-null color.
/// If all rules return a null color, the default color is used.
class MapRuleTheme extends MapTheme {
  MapRuleTheme({
    Color? color,
    Color? contourColor,
    LabelVisibility? labelVisibility,
    LabelStyleBuilder? labelStyleBuilder,
    MarkerBuilder? markerBuilder,
    required List<ColorRule> colorRules,
    BackgroundLabelVisibility? backgroundLabelVisibility,
    BackgroundLabelBuilder? backgroundLabelBuilder,
  })  : _colorRules = colorRules,
        super(
          color: color,
          contourColor: contourColor,
          labelVisibility: labelVisibility,
          labelStyleBuilder: labelStyleBuilder,
          markerBuilder: markerBuilder,
          backgroundLabelBuilder: backgroundLabelBuilder,
          backgroundLabelVisibility: backgroundLabelVisibility,
        );

  final List<ColorRule> _colorRules;

  @override
  bool hasValue() {
    //It is not possible to know in advance, it depends on the rule.
    //TODO: need handle with rule value
    return true;
  }

  @override
  Color? getColor(MapDataSource dataSource, MapFeature feature) {
    Color? color;
    for (ColorRule rule in _colorRules) {
      color = rule(feature);
      if (color != null) {
        break;
      }
    }
    return color ?? super.getColor(dataSource, feature);
  }
}

/// Rule to obtain a color of a feature.
typedef ColorRule = Color? Function(MapFeature feature);
