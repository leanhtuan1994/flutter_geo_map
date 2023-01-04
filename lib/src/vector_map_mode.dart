/// Indicates in which interaction mode the map is working.
enum SimpleMapMode {
  autoFit,
  panAndZoom;

  bool get isAutoFit => this == SimpleMapMode.autoFit;

  bool get isPanAndZoom => this == SimpleMapMode.panAndZoom;
}
