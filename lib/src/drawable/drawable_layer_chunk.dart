import 'dart:ui' as ui;

import '../data/map_feature.dart';
import 'drawable_feature.dart';

class DrawableLayerChunk {
  final List<DrawableFeature> _drawableFeatures = [];
  ui.Image? buffer;

  ui.Rect? _bounds;
  ui.Rect? get bounds => _bounds;

  int _pointsCount = 0;
  int get pointsCount => _pointsCount;

  int get length => _drawableFeatures.length;

  DrawableFeature getDrawableFeature(int index) {
    return _drawableFeatures[index];
  }

  DrawableFeature? getDrawableFeatureByCode(
      {required String key, required String code}) {
    for (var e in _drawableFeatures) {
      if (e.feature.getValue(key) == code) {
        return e;
      }
    }
    return null;
  }

  void add(MapFeature feature) {
    _drawableFeatures.add(DrawableFeature(feature));

    final geometry = feature.geometry;

    _pointsCount += geometry.pointsCount;

    if (_bounds == null) {
      _bounds = geometry.bounds;
    } else {
      _bounds = _bounds!.expandToInclude(geometry.bounds);
    }
  }
}
