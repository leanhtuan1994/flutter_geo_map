import 'package:flutter/rendering.dart';

import '../data/geometries.dart';
import '../data/map_data_source.dart';
import '../data/map_feature.dart';
import '../data/simplified_path.dart';
import '../error.dart';
import '../simplifier.dart';
import '../theme/map_theme.dart';
import 'drawable.dart';
import 'drawable_line.dart';
import 'drawable_polygon.dart';

/// [Drawable] builder.
class DrawableBuilder {
  static Drawable build({
    required MapDataSource dataSource,
    required MapFeature feature,
    required MapTheme theme,
    required Matrix4 worldToCanvas,
    required double scale,
    required GeometrySimplifier simplifier,
  }) {
    final geometry = feature.geometry;

    if (geometry is MapPoint) {
      return _point(
        dataSource: dataSource,
        feature: feature,
        point: geometry,
        theme: theme,
        scale: scale,
        simplifier: simplifier,
      );
    }
    if (geometry is MapLinearRing) {
      return _linearRing(
        feature: feature,
        linearRing: geometry,
        theme: theme,
        worldToCanvas: worldToCanvas,
        simplifier: simplifier,
      );
    }
    if (geometry is MapLineString) {
      return _lineString(
        feature: feature,
        lineString: geometry,
        theme: theme,
        worldToCanvas: worldToCanvas,
        simplifier: simplifier,
      );
    }
    if (geometry is MapMultiLineString) {
      return _multiLineString(
        feature: feature,
        multiLineString: geometry,
        theme: theme,
        worldToCanvas: worldToCanvas,
        simplifier: simplifier,
      );
    }
    if (geometry is MapPolygon) {
      return _polygon(
        feature: feature,
        polygon: geometry,
        theme: theme,
        worldToCanvas: worldToCanvas,
        simplifier: simplifier,
      );
    }
    if (geometry is MapMultiPolygon) {
      return _multiPolygon(
        feature: feature,
        multiPolygon: geometry,
        theme: theme,
        worldToCanvas: worldToCanvas,
        simplifier: simplifier,
      );
    }
    throw SimpleMapError(
        'Unrecognized geometry: ' + geometry.runtimeType.toString());
  }

  static Drawable _point({
    required MapDataSource dataSource,
    required MapFeature feature,
    required MapPoint point,
    required MapTheme theme,
    required double scale,
    required GeometrySimplifier simplifier,
  }) {
    return theme.markerBuilder.build(
      dataSource: dataSource,
      feature: feature,
      offset: Offset(point.x, point.y),
      scale: scale,
    );
  }

  static Drawable _lineString({
    required MapFeature feature,
    required MapLineString lineString,
    required MapTheme theme,
    required Matrix4 worldToCanvas,
    required GeometrySimplifier simplifier,
  }) {
    SimplifiedPath simplifiedPath =
        lineString.toSimplifiedPath(worldToCanvas, simplifier);

    return DrawableLine(simplifiedPath.path, simplifiedPath.pointsCount);
  }

  static Drawable _multiLineString({
    required MapFeature feature,
    required MapMultiLineString multiLineString,
    required MapTheme theme,
    required Matrix4 worldToCanvas,
    required GeometrySimplifier simplifier,
  }) {
    Path path = Path();
    int pointsCount = 0;

    for (MapLineString lineString in multiLineString.linesString) {
      final simplifiedPath =
          lineString.toSimplifiedPath(worldToCanvas, simplifier);
      pointsCount += simplifiedPath.pointsCount;
      path.addPath(simplifiedPath.path, Offset.zero);
    }

    return DrawableLine(path, pointsCount);
  }

  static Drawable _linearRing({
    required MapFeature feature,
    required MapLinearRing linearRing,
    required MapTheme theme,
    required Matrix4 worldToCanvas,
    required GeometrySimplifier simplifier,
  }) {
    final simplifiedPath =
        linearRing.toSimplifiedPath(worldToCanvas, simplifier);
    return DrawablePolygon(simplifiedPath.path, simplifiedPath.pointsCount);
  }

  static Drawable _polygon({
    required MapFeature feature,
    required MapPolygon polygon,
    required MapTheme theme,
    required Matrix4 worldToCanvas,
    required GeometrySimplifier simplifier,
  }) {
    final simplifiedPath = polygon.toSimplifiedPath(worldToCanvas, simplifier);
    return DrawablePolygon(simplifiedPath.path, simplifiedPath.pointsCount);
  }

  static Drawable _multiPolygon({
    required MapFeature feature,
    required MapMultiPolygon multiPolygon,
    required MapTheme theme,
    required Matrix4 worldToCanvas,
    required GeometrySimplifier simplifier,
  }) {
    Path path = Path();
    int pointsCount = 0;
    for (MapPolygon polygon in multiPolygon.polygons) {
      final simplifiedPath =
          polygon.toSimplifiedPath(worldToCanvas, simplifier);
      pointsCount += simplifiedPath.pointsCount;
      path.addPath(simplifiedPath.path, Offset.zero);
    }

    return DrawablePolygon(path, pointsCount);
  }
}
