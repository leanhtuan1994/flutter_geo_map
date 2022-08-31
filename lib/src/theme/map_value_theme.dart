import 'package:flutter/rendering.dart';
import '../data/map_data_source.dart';
import '../data/map_feature.dart';
import '../drawable/marker.dart';
import 'map_theme.dart';

/// Theme for colors by value.
class MapValueTheme extends MapTheme {
  MapValueTheme({
    Color? color,
    Color? contourColor,
    LabelVisibility? labelVisibility,
    LabelStyleBuilder? labelStyleBuilder,
    MarkerBuilder? markerBuilder,
    BackgroundLabelVisibility? backgroundLabelVisibility,
    BackgroundLabelBuilder? backgroundLabelBuilder,
    LabelMarginBuilder? labelMarginBuilder,
    required this.key,
    Map<dynamic, Color>? colors,
    LabelBuilder? labelBuilder,
  })  : _colors = colors,
        super(
          color: color,
          contourColor: contourColor,
          labelVisibility: labelVisibility,
          labelStyleBuilder: labelStyleBuilder,
          markerBuilder: markerBuilder,
          backgroundLabelBuilder: backgroundLabelBuilder,
          backgroundLabelVisibility: backgroundLabelVisibility,
          labelMarginBuilder: labelMarginBuilder,
          labelBuilder: labelBuilder,
        );

  final String key;
  final Map<dynamic, Color>? _colors;

  @override
  bool hasValue() {
    return (_colors != null && _colors!.isNotEmpty) || super.hasValue();
  }

  @override
  Color? getColor(MapDataSource dataSource, MapFeature feature) {
    if (_colors != null) {
      dynamic value = feature.getValue(key);
      if (value != null && _colors!.containsKey(value)) {
        return _colors![value]!;
      }
    }
    return super.getColor(dataSource, feature);
  }
}
