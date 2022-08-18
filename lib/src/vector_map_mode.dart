/// Indicates in which interaction mode the map is working.
enum VectorMapMode {
  autoFit,
  panAndZoom;

  bool get isAutoFit => this == VectorMapMode.autoFit;

  bool get isPanAndZoom => this == VectorMapMode.panAndZoom;
}
