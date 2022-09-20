import 'dart:collection';
import 'dart:ui';

import '../data_reader.dart';
import 'geometries.dart';
import 'map_feature.dart';
import 'property_limits.dart';

/// [VectorMap] data source.
class MapDataSource {
  MapDataSource._({
    required this.features,
    required this.bounds,
    required this.pointsCount,
    Map<String, PropertyLimits>? limits,
  }) : _limits = limits;

  final UnmodifiableMapView<int, MapFeature> features;
  final Rect? bounds;
  final int pointsCount;
  final Map<String, PropertyLimits>? _limits;

  /// Create a [MapDataSource] from a list of [MapFeature].
  static MapDataSource fromFeatures(List<MapFeature> features) {
    Rect? boundsFromGeometry;
    int pointsCount = 0;
    if (features.isNotEmpty) {
      boundsFromGeometry = features.first.geometry.bounds;
    }
    Map<String, PropertyLimits> limits = <String, PropertyLimits>{};
    Map<int, MapFeature> featuresMap = <int, MapFeature>{};
    for (MapFeature feature in features) {
      final geometry = feature.geometry;

      featuresMap[feature.id] = feature;
      pointsCount += geometry.pointsCount;
      if (boundsFromGeometry == null) {
        boundsFromGeometry = geometry.bounds;
      } else {
        boundsFromGeometry =
            boundsFromGeometry.expandToInclude(geometry.bounds);
      }

      if (feature.properties != null) {
        for (final entry in feature.properties!.entries) {
          final value = entry.value;
          double? doubleValue;

          if (value is int) {
            doubleValue = value.toDouble();
          } else if (value is double) {
            doubleValue = value;
          }

          if (doubleValue != null) {
            final key = entry.key;
            if (limits.containsKey(key)) {
              PropertyLimits propertyLimits = limits[key]!;
              propertyLimits.expand(doubleValue);
            } else {
              limits[key] = PropertyLimits(doubleValue);
            }
          }
        }
      }
    }

    return MapDataSource._(
      features: UnmodifiableMapView<int, MapFeature>(featuresMap),
      bounds: boundsFromGeometry,
      pointsCount: pointsCount,
      limits: limits.isNotEmpty ? limits : null,
    );
  }

  /// Loads a [MapDataSource] from GeoJSON.
  ///
  /// Geometries are always loaded.
  /// The [keys] argument defines which properties must be loaded.
  /// The [parseToNumber] argument defines which properties will have
  /// numeric values in quotes parsed to numbers.
  static Future<MapDataSource> geoJson({
    required String geoJson,
    String? labelKey,
    List<String>? keys,
    List<String>? parseToNumber,
    String? colorKey,
    ColorValueFormat colorValueFormat = ColorValueFormat.hex,
    String? filterKey,
    String? filterValue,
  }) async {
    final reader = MapFeatureReader(
      labelKey: labelKey,
      keys: keys?.toSet(),
      parseToNumber: parseToNumber?.toSet(),
      colorKey: colorKey,
      colorValueFormat: colorValueFormat,
    );

    final features = await reader.read(
      geoJson,
      filterKey: filterKey,
      filterValue: filterValue,
    );
    return fromFeatures(features);
  }

  /// Loads a [MapDataSource] from geometries.
  /// [MapDataSource] features will have no properties.
  factory MapDataSource.geometries(List<MapGeometry> geometries) {
    Rect? boundsFromGeometry;
    int pointsCount = 0;
    Map<int, MapFeature> featuresMap = <int, MapFeature>{};
    int id = 1;

    for (final geometry in geometries) {
      featuresMap[id] = MapFeature(id: id, geometry: geometry);
      pointsCount += geometry.pointsCount;

      if (boundsFromGeometry == null) {
        boundsFromGeometry = geometry.bounds;
      } else {
        boundsFromGeometry =
            boundsFromGeometry.expandToInclude(geometry.bounds);
      }

      id++;
    }

    return MapDataSource._(
      features: UnmodifiableMapView<int, MapFeature>(featuresMap),
      bounds: boundsFromGeometry,
      pointsCount: pointsCount,
    );
  }

  PropertyLimits? getPropertyLimits(String key) {
    if (_limits != null && _limits!.containsKey(key)) {
      return _limits![key]!;
    }
    return null;
  }
}
