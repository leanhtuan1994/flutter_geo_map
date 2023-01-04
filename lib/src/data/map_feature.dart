import 'dart:collection';

import 'package:equatable/equatable.dart';

import 'geometries.dart';

/// A representation of a real-world object on a map.
class MapFeature extends Equatable {
  MapFeature({
    required this.id,
    required this.geometry,
    Map<String, dynamic>? properties,
    this.label,
  }) : properties = properties != null ? UnmodifiableMapView(properties) : null;

  final int id;
  final String? label;
  final UnmodifiableMapView<String, dynamic>? properties;
  final MapGeometry geometry;

  dynamic getValue(String key) {
    if (properties?.containsKey(key) ?? false) {
      return properties![key];
    }

    return null;
  }

  double? getDoubleValue(String key) {
    final d = getValue(key);
    if (d != null) {
      if (d is double) {
        return d;
      } else if (d is int) {
        return d.toDouble();
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        geometry,
        properties,
        label,
      ];
}
