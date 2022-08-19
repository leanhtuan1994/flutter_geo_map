import 'dart:ui';

class PanZoom {
  PanZoom({
    required this.initialMouseLocation,
    required this.initialMapScale,
    required this.translateX,
    required this.translateY,
  });

  final double initialMapScale;
  final Offset initialMouseLocation;
  final double translateX;
  final double translateY;

  bool _rebuildSimplifiedGeometry = false;
  bool get rebuildSimplifiedGeometry => _rebuildSimplifiedGeometry;

  double newScale({required double currentMapScale, required double scale}) {
    if (scale != 1) {
      final newScale = initialMapScale * scale;
      final delta = (1 - (newScale / currentMapScale)).abs();
      if (delta > 0.05) {
        _rebuildSimplifiedGeometry = true;
        return newScale;
      }
    }
    return currentMapScale;
  }
}
