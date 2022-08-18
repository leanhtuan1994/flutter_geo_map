import 'package:flutter/material.dart';

import 'addon/map_addon.dart';
import 'data/map_feature.dart';
import 'drawable/drawable_feature.dart';
import 'drawable/drawable_layer.dart';
import 'drawable/drawable_layer_chunk.dart';
import 'low_quality_mode.dart';
import 'map_highlight.dart';
import 'map_painter.dart';
import 'pan_zoom.dart';
import 'vector_map_controller.dart';

/// Vector map widget.
class VectorMap extends StatefulWidget {
  const VectorMap({
    Key? key,
    this.controller,
    this.color,
    this.highlightRule,
    this.hoverListener,
    this.onFeaturePress,
    this.addons,
    this.placeHolder,
    this.lowQualityMode,
    this.borderColor = Colors.black54,
    this.borderThickness = 1,
    this.layersPadding = const EdgeInsets.all(8),
  }) : super(key: key);

  /// The Controller
  ///
  final VectorMapController? controller;

  /// Background color
  ///
  final Color? color;

  /// A placeholder widget that is displayed when layers empty
  final Widget? placeHolder;

  /// Set highlight rule that can be select or not
  final HighlightRule? highlightRule;

  /// Callback if feature highlighted
  final HighlightListener? hoverListener;

  /// Callback any feature pressed
  final FeaturePressListener? onFeaturePress;

  /// Addons
  final List<MapAddon>? addons;

  /// Handle low quality for some case improve performance
  final LowQualityMode? lowQualityMode;

  final EdgeInsetsGeometry layersPadding;

  /// Border color for parent layers map widget
  final Color borderColor;

  // Border size for parent layers map widget
  final double borderThickness;

  @override
  State<StatefulWidget> createState() => _VectorMapState();
}

/// [VectorMap] state.
class _VectorMapState extends State<VectorMap> {
  late VectorMapController _controller;

  PanZoom? _panZoom;

  bool get _onPanAndZoom => _panZoom != null;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? VectorMapController();

    _controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant VectorMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null &&
        widget.controller != oldWidget.controller) {
      _controller.removeListener(_rebuild);
      _controller = widget.controller!;
      _controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? content;
    if (_controller.hasLayer) {
      final mapCanvas = _buildMapCanvas();
      if (widget.addons != null) {
        final children = _buildMapWithAddons(map: mapCanvas);
        content = CustomMultiChildLayout(
          children: children,
          delegate: _VectorMapLayoutDelegate(children.length),
        );
      } else {
        content = mapCanvas;
      }
    } else if (widget.placeHolder != null) {
      content = widget.placeHolder;
    }

    final border = widget.borderThickness > 0
        ? Border.all(color: widget.borderColor, width: widget.borderThickness)
        : null;

    final decoration = widget.color != null || border != null
        ? BoxDecoration(color: widget.color, border: border)
        : null;

    return Container(decoration: decoration, child: content);
  }

  void _rebuild() {
    setState(() {
      // rebuild
    });
  }

  List<LayoutId> _buildMapWithAddons({required Widget map}) {
    List<LayoutId> children = [LayoutId(id: 0, child: map)];
    int count = 1;

    for (MapAddon addon in widget.addons!) {
      DrawableFeature? highlight;

      if (_controller.highlight != null &&
          _controller.highlight is MapSingleHighlight) {
        highlight =
            (_controller.highlight as MapSingleHighlight).drawableFeature;
      }
      children.add(
        LayoutId(
          id: count,
          child: addon.buildWidget(
            context: context,
            mapApi: _controller,
            highlight: highlight?.feature,
          ),
        ),
      );

      count++;
    }

    return children;
  }

  /// Builds the canvas area
  Widget _buildMapCanvas() {
    Widget mapCanvas = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
        return const SizedBox.shrink();
      }
      Size canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
      _controller.setCanvasSize(canvasSize);

      return ClipRect(
        child: CustomPaint(
          painter: MapPainter(controller: _controller),
          child: Container(),
        ),
      );
    });

    mapCanvas = GestureDetector(
      child: mapCanvas,
      onTapDown: (details) {
        _onFeatureTap(
          localPosition: details.localPosition,
          canvasToWorld: _controller.canvasToWorld,
        );
      },
      onScaleStart: (details) {
        if (_controller.mode.isPanAndZoom) {
          _controller.notifyPanZoomMode(start: true);
          setState(() {
            _panZoom = PanZoom(
              initialMouseLocation: details.localFocalPoint,
              initialMapScale: _controller.scale,
              translateX: _controller.translateX,
              translateY: _controller.translateY,
            );
          });
        }
      },
      onScaleUpdate: (details) {
        if (_panZoom != null) {
          if (details.pointerCount == 1) {
            // pan only
            // _panZoom!.lastLocalPosition = details.localFocalPoint;
            final diffX =
                _panZoom!.initialMouseLocation.dx - details.localFocalPoint.dx;
            final diffY =
                _panZoom!.initialMouseLocation.dy - details.localFocalPoint.dy;

            _controller.translate(
              _panZoom!.translateX - diffX,
              _panZoom!.translateY - diffY,
            );
          } else if (details.pointerCount > 1) {
            // zoom
            final newScale = _panZoom!.newScale(
              currentMapScale: _controller.scale,
              scale: details.scale,
            );

            _controller.zoom(details.localFocalPoint, newScale);
          }
        }
      },
      onScaleEnd: (details) {
        if (_panZoom != null) {
          _controller.notifyPanZoomMode(
            start: false,
            rebuildSimplifiedGeometry: _panZoom!.rebuildSimplifiedGeometry,
          );

          // clear pan&zoom
          setState(() {
            _panZoom = null;
          });
        }
      },
    );

    return Container(child: mapCanvas, padding: widget.layersPadding);
  }

  void _onFeatureTap(
      {required Offset localPosition, required Matrix4 canvasToWorld}) {
    if (_onPanAndZoom) return;

    final worldCoordinate =
        MatrixUtils.transformPoint(canvasToWorld, localPosition);
    MapFeature? feature;
    MapSingleHighlight? hoverHighlightRule;

    for (int layerIndex = _controller.layersCount - 1;
        layerIndex >= 0;
        layerIndex--) {
      final drawableLayer = _controller.getDrawableLayer(layerIndex);
      final drawableFeature =
          _findDrawableFeature(drawableLayer, worldCoordinate);

      if (drawableFeature != null) {
        feature = drawableFeature.feature;
        final layer = drawableLayer.layer;

        hoverHighlightRule = MapSingleHighlight(
          layerId: layer.id,
          drawableFeature: drawableFeature,
        );

        break;
      }
    }

    if (feature != null) {
      widget.onFeaturePress?.call(feature);
    }

    if (_controller.highlight != hoverHighlightRule) {
      _updateHighlight(hoverHighlightRule);
    }
  }

  /// Finds the first feature that contains a coordinate.
  DrawableFeature? _findDrawableFeature(
      DrawableLayer drawableLayer, Offset worldCoordinate) {
    for (DrawableLayerChunk chunk in drawableLayer.chunks) {
      for (int index = 0; index < chunk.length; index++) {
        final drawableFeature = chunk.getDrawableFeature(index);
        final feature = drawableFeature.feature;
        if (widget.highlightRule != null &&
            widget.highlightRule!(feature) == false) {
          continue;
        }
        final drawable = drawableFeature.drawable;
        if (drawable != null && drawable.contains(worldCoordinate)) {
          return drawableFeature;
        }
      }
    }
    return null;
  }

  void _updateHighlight(MapSingleHighlight? hoverHighlightRule) {
    if (hoverHighlightRule != null) {
      _controller.setHighlight(hoverHighlightRule);
    } else {
      _controller.clearHighlight();
    }
    widget.hoverListener?.call(hoverHighlightRule?.drawableFeature?.feature);
  }
}

/// The [VectorMap] layout.
class _VectorMapLayoutDelegate extends MultiChildLayoutDelegate {
  _VectorMapLayoutDelegate(this.count);

  final int count;

  @override
  void performLayout(Size size) {
    Size childSize = Size.zero;
    for (int id = 0; id < count; id++) {
      if (hasChild(id)) {
        if (id == 0) {
          childSize = layoutChild(id, BoxConstraints.tight(size));
          positionChild(id, Offset.zero);
        } else {
          childSize = layoutChild(id, BoxConstraints.loose(size));
          positionChild(
            id,
            Offset(
              size.width - childSize.width,
              size.height - childSize.height,
            ),
          );
        }
      }
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) => false;
}

typedef FeaturePressListener = void Function(MapFeature feature);

typedef HighlightRule = bool Function(MapFeature feature);

typedef HighlightListener = void Function(MapFeature? feature);
