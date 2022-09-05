import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../vector_map.dart';
import 'draw_utils.dart';

class VectorMapController extends ChangeNotifier implements VectorMapApi {
  VectorMapController({
    List<MapLayer>? layers,
    this.contourThickness = 1,
    this.delayToRefreshResolution = 1000,
    VectorMapMode mode = VectorMapMode.autoFit,
    this.maxScale = 30000,
    this.minScale = 0.1,
    this.barrierDismissibleHighlight = true,
    this.isDrawBuffer = false,
  })  : _mode = mode,
        _scale = minScale {
    layers?.forEach(_addLayer);
    _afterLayersChange();

    if (maxScale <= minScale) {
      throw ArgumentError('maxScale must be bigger than minScale');
    }
  }

  VectorMapMode _mode;
  VectorMapMode get mode => _mode;
  set mode(VectorMapMode mode) {
    if (_mode != mode) {
      _mode = mode;
      if (mode.isAutoFit) {
        fit();
      }
    }
  }

  _UpdateState _updateState = _UpdateState.stopped;

  final HashMap<int, MapLayer> _layerIdAndLayer = HashMap<int, MapLayer>();
  final List<DrawableLayer> _drawableLayers = [];

  final HashMap<int, DrawableLabelData> _bgIdAndRect =
      HashMap<int, DrawableLabelData>();

  List<DrawableLabelData> get bgRect {
    final List<DrawableLabelData> bgRect = [];
    _bgIdAndRect.forEach((key, value) {
      bgRect.add(value);
    });
    return bgRect;
  }

  bool _rebuildSimplifiedGeometry = true;

  Size? _lastCanvasSize;
  Size? get lastCanvasSize => _lastCanvasSize;

  /// Represents the bounds of all layers.
  Rect? _worldBounds;
  Rect? get worldBounds => _worldBounds;

  double zoomFactor = 0.1;

  final double maxScale;
  final double minScale;

  double _scale;
  double get scale => _scale;

  double _translateX = 0;
  double get translateX => _translateX;

  double _translateY = 0;
  double get translateY => _translateY;

  /// Matrix to be used to convert world coordinates to canvas coordinates.
  Matrix4 _worldToCanvas = VectorMapController._buildMatrix4;
  Matrix4 get worldToCanvas => _worldToCanvas;

  /// Matrix to be used to convert canvas coordinates to world coordinates.
  Matrix4 _canvasToWorld = VectorMapController._buildMatrix4;
  Matrix4 get canvasToWorld => _canvasToWorld;

  MapHighlight? _highlight;
  MapHighlight? get highlight => _highlight;

  final bool isDrawBuffer;
  bool _drawBuffers = false;
  bool get drawBuffers => isDrawBuffer && _drawBuffers;

  int _currentDrawablesUpdateTicket = 0;

  /// The Border size value
  /// Using for [DrawUtils] draw contour
  /// Default value is 1
  final double contourThickness;

  final int delayToRefreshResolution;

  /// Check user can touchable out size of [MapLayer] to remove highlight drawable
  /// Default value is true
  final bool barrierDismissibleHighlight;

  /// Adds a layer.
  ///
  /// Listeners will be notified.
  void addLayer(MapLayer layer) {
    _addLayer(layer);
    _afterLayersChange();
    notifyListeners();
  }

  void _addLayer(MapLayer layer) {
    if (_layerIdAndLayer.containsKey(layer.id)) {
      throw VectorMapError('Duplicated layer id: ' + layer.id.toString());
    }

    _layerIdAndLayer[layer.id] = layer;
    _drawableLayers.add(DrawableLayer(layer));
  }

  void _afterLayersChange() {
    _worldBounds = DrawableLayer.boundsOf(_drawableLayers);
  }

  void addBgRect({required DrawableLabelData data, required int id}) {
    _addRect(data, id);
    //notifyListeners();
  }

  void _addRect(DrawableLabelData data, int id) {
    _bgIdAndRect[id] = data;
  }

  /// Gets the count of layers.
  int get layersCount {
    return _drawableLayers.length;
  }

  /// Check if there is any layer.
  bool get hasLayer {
    return _drawableLayers.isNotEmpty;
  }

  /// Gets a layer given an index
  MapLayer getLayerByIndex(int index) {
    if (index >= 0 && index < _drawableLayers.length) {
      return _drawableLayers[index].layer;
    }

    throw VectorMapError('Invalid layer index: $index');
  }

  /// Gets a layer given an id.
  MapLayer getLayerById(int id) {
    final layer = _layerIdAndLayer[id];
    if (layer == null) {
      throw VectorMapError('Invalid layer id: $id');
    }
    return layer;
  }

  bool hasLayerId(int id) {
    return _layerIdAndLayer.containsKey(id);
  }

  bool get highlightDrawable {
    for (final drawableLayer in _drawableLayers) {
      if (drawableLayer.layer.highlightDrawable) {
        return true;
      }
    }
    return false;
  }

  DrawableLayer getDrawableLayer(int index) {
    return _drawableLayers[index];
  }

  @override
  void clearHighlight() {
    _highlight = null;
    if (highlightDrawable) {
      notifyListeners();
    }
  }

  @override
  void setHighlight(MapHighlight newHighlight) {
    _highlight = newHighlight;
    if (highlightDrawable) {
      notifyListeners();
    }
  }

  @internal
  void notifyPanZoomMode(
      {required bool start, bool rebuildSimplifiedGeometry = false}) {
    if (start) {
      _drawBuffers = false;
      // cancel running update
      _cancelDrawablesUpdate();
      // cancel scheduled update
      _nextDrawablesUpdateTicket;
    } else {
      if (rebuildSimplifiedGeometry) {
        // only turn on if true. Avoid last false due pan after zoom generated
        // by gesture
        _rebuildSimplifiedGeometry = true;
      }
      // schedule the drawables build
      _scheduleDrawablesUpdate(delayed: true);
    }
  }

  @internal
  void setCanvasSize(Size canvasSize) {
    if (_lastCanvasSize != canvasSize) {
      _rebuildSimplifiedGeometry = _lastCanvasSize != canvasSize;
      bool first = _lastCanvasSize == null;
      bool needFit = (first ||
          (_mode == VectorMapMode.autoFit && _rebuildSimplifiedGeometry));
      _lastCanvasSize = canvasSize;
      if (needFit) {
        _fit(canvasSize);
      }

      _drawBuffers = false;
      _cancelDrawablesUpdate();
      if (first) {
        // first build without delay
        _scheduleDrawablesUpdate(delayed: false);
      } else {
        // schedule the drawables build
        _scheduleDrawablesUpdate(delayed: true);
      }
    }
  }

  @internal
  void translate(double translateX, double translateY) {
    _drawBuffers = false;
    _translateX = translateX;
    _translateY = translateY;
    _buildMatrices4();
    notifyListeners();
  }

  /// Fits all layers to canvas size.
  ///
  /// Listeners will be notified.
  void fit() {
    if (_lastCanvasSize != null) {
      _fit(_lastCanvasSize!);
      _drawBuffers = false;
      _scheduleDrawablesUpdate(delayed: true);
      notifyListeners();
    }
  }

  double _limitScale(double scale) {
    scale = math.max(minScale, scale);
    return math.min(maxScale, scale);
  }

  void _fit(Size canvasSize) {
    if (_worldBounds != null && canvasSize.isEmpty == false) {
      final scaleX = canvasSize.width / _worldBounds!.width;
      final scaleY = canvasSize.height / _worldBounds!.height;
      _scale = _limitScale(math.min(scaleX, scaleY));

      /// Moving to center
      _translateX =
          (canvasSize.width / 2.0) - (_scale * _worldBounds!.center.dx);
      _translateY =
          (canvasSize.height / 2.0) + (_scale * _worldBounds!.center.dy);
      _buildMatrices4();
    }
  }

  /// Zooms on the canvas center.
  ///
  /// Listeners will be notified.
  void zoomOnCenter({bool zoomIn = false}) {
    if (_lastCanvasSize != null) {
      _zoom(
        _lastCanvasSize!,
        Offset(_lastCanvasSize!.width / 2, _lastCanvasSize!.height / 2),
        zoomIn,
      );
    }
  }

  void moveTargetToCenter({required Offset locationOnCanvas}) {
    if (_lastCanvasSize != null) {
      final dx = _lastCanvasSize!.width / 2;
      final dy = _lastCanvasSize!.height / 2;

      final diffX = locationOnCanvas.dx - dx;
      final diffY = locationOnCanvas.dy - dy;

      translate(_translateX - diffX, _translateY - diffY);
    }
  }

  /// It takes an offset on the canvas and a boolean, and it zooms in or out on that location
  ///
  /// Args:
  ///   locationOnCanvas (Offset): The location on the canvas where the zoom should be centered.
  ///   zoomIn (bool): true if you want to zoom in, false if you want to zoom out
  void zoomOnLocation(Offset locationOnCanvas, {bool zoomIn = false}) {
    if (_lastCanvasSize != null) {
      _zoom(_lastCanvasSize!, locationOnCanvas, zoomIn);
    }
  }

  /// > Zoom in or out on the canvas, centered on the given location
  ///
  /// Args:
  ///   canvasSize (Size): The size of the canvas.
  ///   locationOnCanvas (Offset): The location on the canvas where the user tapped.
  ///   zoomIn (bool): true if you want to zoom in, false if you want to zoom out
  void _zoom(Size canvasSize, Offset locationOnCanvas, bool zoomIn) {
    _drawBuffers = false;
    _cancelDrawablesUpdate();
    _rebuildSimplifiedGeometry = true;
    double zoom = 1;
    if (zoomIn) {
      zoom += zoomFactor;
    } else {
      zoom -= zoomFactor;
    }
    final newScale = _limitScale(_scale * zoom);
    Offset refInWorld =
        MatrixUtils.transformPoint(_canvasToWorld, locationOnCanvas);
    _translateX = locationOnCanvas.dx - (refInWorld.dx * newScale);
    _translateY = locationOnCanvas.dy + (refInWorld.dy * newScale);
    _scale = newScale;
    _buildMatrices4();
    // schedule the drawables build
    _scheduleDrawablesUpdate(delayed: true);
    notifyListeners();
  }

  @internal
  void zoom(Offset locationOnCanvas, double newScale) {
    if (_scale != newScale) {
      newScale = _limitScale(newScale);
      if (_scale != newScale) {
        final refInWorld =
            MatrixUtils.transformPoint(_canvasToWorld, locationOnCanvas);
        _translateX = locationOnCanvas.dx - (refInWorld.dx * newScale);
        _translateY = locationOnCanvas.dy + (refInWorld.dy * newScale);
        _scale = newScale;
        _buildMatrices4();
        notifyListeners();
      }
    }
  }

  /// It builds a 4x4 matrix from a 3x3 matrix
  ///
  void _buildMatrices4() {
    _worldToCanvas = VectorMapController._buildMatrix4;
    _worldToCanvas.translate(_translateX, _translateY, 0);
    _worldToCanvas.scale(_scale, -_scale, 1);

    _canvasToWorld = Matrix4.inverted(_worldToCanvas);
  }

  void _cancelDrawablesUpdate() {
    if (_updateState != _UpdateState.stopped) {
      _updateState = _UpdateState.canceling;
    }
  }

  void _clearBuffers() {
    for (DrawableLayer drawableLayer in _drawableLayers) {
      for (DrawableLayerChunk chunk in drawableLayer.chunks) {
        chunk.buffer = null;
      }
    }
  }

  int get _nextDrawablesUpdateTicket {
    _currentDrawablesUpdateTicket++;
    if (_currentDrawablesUpdateTicket == 999999) {
      _currentDrawablesUpdateTicket = 0;
    }
    return _currentDrawablesUpdateTicket;
  }

  void _scheduleDrawablesUpdate({required bool delayed}) {
    if (delayed) {
      int ticket = _nextDrawablesUpdateTicket;
      Future.delayed(
        Duration(milliseconds: delayToRefreshResolution),
        () => _startDrawablesUpdate(ticket: ticket),
      );
    } else {
      Future.microtask(
        () => _startDrawablesUpdate(ticket: _currentDrawablesUpdateTicket),
      );
    }
  }

  void _startDrawablesUpdate({required int ticket}) {
    if (_currentDrawablesUpdateTicket == ticket) {
      if (_lastCanvasSize != null) {
        _clearBuffers();
        if (_updateState == _UpdateState.stopped) {
          _updateDrawables();
        } else {
          _updateState = _UpdateState.restarting;
        }
      }
      _drawBuffers = true;
    }
  }

  Future<void> _updateDrawables() async {
    _updateState = _UpdateState.running;
    while (_updateState == _UpdateState.running) {
      for (DrawableLayer drawableLayer in _drawableLayers) {
        if (_updateState != _UpdateState.running) {
          break;
        }

        final layer = drawableLayer.layer;
        final theme = layer.theme;
        final dataSource = layer.dataSource;

        for (DrawableLayerChunk chunk in drawableLayer.chunks) {
          if (_updateState != _UpdateState.running) {
            break;
          }
          for (int index = 0; index < chunk.length; index++) {
            if (_updateState != _UpdateState.running) {
              break;
            }
            DrawableFeature drawableFeature = chunk.getDrawableFeature(index);
            if (_rebuildSimplifiedGeometry) {
              drawableFeature.drawable = DrawableBuilder.build(
                dataSource: dataSource,
                feature: drawableFeature.feature,
                theme: theme,
                worldToCanvas: _worldToCanvas,
                scale: _scale,
                simplifier: IntegerSimplifier(),
              );
            }
          }
          if (_updateState != _UpdateState.running) {
            break;
          }

          if (_lastCanvasSize != null) {
            final canvasInWorld = MatrixUtils.transformRect(
              _canvasToWorld,
              Rect.fromLTWH(
                0,
                0,
                _lastCanvasSize!.width,
                _lastCanvasSize!.height,
              ),
            );

            if (chunk.bounds != null && chunk.bounds!.overlaps(canvasInWorld)) {
              chunk.buffer = await _createBuffer(
                chunk: chunk,
                layer: drawableLayer.layer,
                canvasSize: _lastCanvasSize!,
              );
            }
          }

          if (_updateState == _UpdateState.running) {
            notifyListeners();
          }

          await Future.delayed(Duration.zero);
        }
      }
      if (_updateState == _UpdateState.running) {
        _updateState = _UpdateState.stopped;
        _rebuildSimplifiedGeometry = false;
      } else if (_updateState == _UpdateState.canceling) {
        _clearBuffers();
        _updateState = _UpdateState.stopped;
      } else if (_updateState == _UpdateState.restarting) {
        _clearBuffers();
        _updateState = _UpdateState.running;
      }
    }
  }

  Future<ui.Image> _createBuffer({
    required DrawableLayerChunk chunk,
    required MapLayer layer,
    required Size canvasSize,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(Offset.zero, Offset(canvasSize.width, canvasSize.height)),
    );

    canvas.save();
    applyMatrixOn(canvas);

    DrawUtils.draw(
      canvas: canvas,
      chunk: chunk,
      layer: layer,
      contourThickness: contourThickness,
      scale: _scale,
      antiAlias: true,
    );

    canvas.restore();

    final picture = recorder.endRecording();
    return picture.toImage(canvasSize.width.ceil(), canvasSize.height.ceil());
  }

  Future<MemoryImage?> toMemoryImageProvider(ui.Image image) async {
    try {
      final imageByteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (imageByteData == null) {
        return null;
      }

      final uint8list = imageByteData.buffer.asUint8List();
      return MemoryImage(uint8list);
    } catch (error) {
      return null;
    }
  }

  /// Applies a matrix on the canvas.
  void applyMatrixOn(Canvas canvas) {
    canvas.translate(_translateX, _translateY);
    canvas.scale(_scale, -_scale);
  }

  static Matrix4 get _buildMatrix4 {
    return Matrix4(
      1,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
    );
  }
}

enum _UpdateState { stopped, running, canceling, restarting }

class DrawableLabelData {
  final ui.Rect rect;
  final MapFeature mapFeature;

  const DrawableLabelData({
    required this.rect,
    required this.mapFeature,
  });
}
