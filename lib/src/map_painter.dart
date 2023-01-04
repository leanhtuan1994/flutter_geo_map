// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

import 'data/map_feature.dart';
import 'data/map_layer.dart';
import 'draw_utils.dart';
import 'drawable/drawable.dart';
import 'drawable/drawable_feature.dart';
import 'drawable/drawable_layer.dart';
import 'drawable/drawable_layer_chunk.dart';
import 'map_highlight.dart';
import 'simple_map_controller.dart';
import 'theme/map_theme.dart';

const double MARKER_WIDTH = 20.0;

/// Painter for [VectorMap].
class MapPainter extends CustomPainter {
  const MapPainter({required this.controller});

  final SimpleMapController controller;

  @override
  void paint(Canvas canvas, Size size) {
    MapHighlight? highlight = controller.highlight;

    DrawableLayer? overlayContourDrawableLayer;

    // drawing layers
    for (int layerIndex = 0;
        layerIndex < controller.layersCount;
        layerIndex++) {
      DrawableLayer drawableLayer = controller.getDrawableLayer(layerIndex);
      for (DrawableLayerChunk chunk in drawableLayer.chunks) {
        if (controller.drawBuffers && chunk.buffer != null) {
          canvas.drawImage(chunk.buffer!, Offset.zero, Paint());
        } else {
          // resizing, panning or zooming
          canvas.save();

          controller.applyMatrixOn(canvas);

          //! drawing contour only to be faster
          // DrawUtils.drawContour(
          //   canvas: canvas,
          //   chunk: chunk,
          //   layer: drawableLayer.layer,
          //   contourThickness: controller.contourThickness,
          //   scale: controller.scale,
          //   antiAlias: false,
          // );

          DrawUtils.draw(
            canvas: canvas,
            chunk: chunk,
            layer: drawableLayer.layer,
            contourThickness: controller.contourThickness,
            scale: controller.scale,
            antiAlias: false,
          );

          canvas.restore();
        }
      }

      MapLayer layer = drawableLayer.layer;

      // highlighting
      if (highlight != null &&
          highlight.layerId == layer.id &&
          layer.highlightTheme != null) {
        if (controller.contourThickness > 0 &&
            layer.highlightTheme!.overlayContour) {
          overlayContourDrawableLayer = drawableLayer;
        }

        canvas.save();
        controller.applyMatrixOn(canvas);

        if (layer.highlightTheme!.color != null) {
          var paint = Paint()
            ..style = PaintingStyle.fill
            ..color = layer.highlightTheme!.color!
            ..isAntiAlias = true;
          if (highlight is MapSingleHighlight) {
            DrawableFeature? drawableFeature = highlight.drawableFeature;
            Drawable? drawable = drawableFeature?.drawable;
            if (drawable != null && drawable.visible && drawable.hasFill) {
              drawable.drawOn(canvas, paint, controller.scale);
            }
          } else {
            DrawUtils.drawHighlight(
              canvas: canvas,
              drawableLayer: drawableLayer,
              paint: paint,
              scale: controller.scale,
              fillOnly: true,
              highlight: highlight,
            );
          }
        }

        if (controller.contourThickness > 0 &&
            layer.highlightTheme!.overlayContour == false) {
          _drawHighlightContour(canvas, drawableLayer, controller);
        }

        canvas.restore();
      }
    }

    // drawing the overlay highlight contour
    if (overlayContourDrawableLayer != null) {
      canvas.save();
      controller.applyMatrixOn(canvas);
      _drawHighlightContour(canvas, overlayContourDrawableLayer, controller);
      canvas.restore();
    }

    // drawing labels
    for (int layerIndex = 0;
        layerIndex < controller.layersCount;
        layerIndex++) {
      final drawableLayer = controller.getDrawableLayer(layerIndex);
      final layer = drawableLayer.layer;
      final dataSource = layer.dataSource;
      final theme = layer.theme;
      final highlightTheme = layer.highlightTheme;
      if (theme.labelVisibility != null ||
          (highlightTheme != null && highlightTheme.labelVisibility != null)) {
        for (DrawableLayerChunk chunk in drawableLayer.chunks) {
          for (int index = 0; index < chunk.length; index++) {
            DrawableFeature drawableFeature = chunk.getDrawableFeature(index);
            MapFeature feature = drawableFeature.feature;
            Drawable? drawable = drawableFeature.drawable;
            if (drawable != null && drawable.visible && feature.label != null) {
              LabelVisibility? labelVisibility;
              BackgroundLabelVisibility? backgroundVisibility;
              MarkerVisibility? markerVisibility;

              if (highlight != null &&
                  highlight.layerId == layer.id &&
                  highlight.applies(feature) &&
                  highlightTheme != null &&
                  highlightTheme.labelVisibility != null) {
                labelVisibility = highlightTheme.labelVisibility;
                backgroundVisibility = highlightTheme.backgroundLabelVisibility;
                markerVisibility = highlightTheme.markerVisibility;
              } else {
                labelVisibility = theme.labelVisibility;
                backgroundVisibility = theme.backgroundLabelVisibility;
                markerVisibility = theme.markerVisibility;
              }

              backgroundVisibility ??= theme.backgroundLabelVisibility;
              markerVisibility ??= theme.markerVisibility;

              if (labelVisibility != null && labelVisibility(feature)) {
                LabelStyleBuilder? labelStyleBuilder;
                BackgroundLabelBuilder? backgroundLabelBuilder;
                LabelMarginBuilder? labelMarginBuilder;
                LabelBuilder? labelBuilder;
                bool? modifiedCenter;

                // MapHighlightTheme? highlightTheme;

                if (highlight != null &&
                    highlight.applies(feature) &&
                    highlightTheme != null) {
                  labelStyleBuilder = highlightTheme.labelStyleBuilder;
                  backgroundLabelBuilder =
                      highlightTheme.backgroundLabelBuilder;
                  labelMarginBuilder = highlightTheme.labelMarginBuilder;
                  labelBuilder = highlightTheme.labelBuilder;
                  modifiedCenter = highlightTheme.modifiedCenter;
                }

                final featureColor = MapTheme.getFeatureColor(
                  dataSource,
                  feature,
                  theme,
                  highlightTheme,
                );

                labelStyleBuilder ??= theme.labelStyleBuilder;

                backgroundLabelBuilder ??= theme.backgroundLabelBuilder;
                labelMarginBuilder ??= theme.labelMarginBuilder;
                labelBuilder ??= theme.labelBuilder;
                modifiedCenter ??= theme.modifiedCenter;

                bool isShowBackground = false;

                if (backgroundVisibility != null &&
                    backgroundVisibility(feature)) {
                  isShowBackground = true;
                }

                bool isShowMarker = false;

                if (markerVisibility != null && markerVisibility(feature)) {
                  isShowMarker = true;
                }

                _drawLabel(
                  index: index,
                  canvas: canvas,
                  feature: feature,
                  drawable: drawable,
                  featureColor: featureColor,
                  labelStyleBuilder: labelStyleBuilder,
                  isShowBackground: isShowBackground,
                  backgroundLabelBuilder: backgroundLabelBuilder,
                  labelMarginBuilder: labelMarginBuilder,
                  labelBuilder: labelBuilder,
                  modifiedCenter: modifiedCenter,
                  isShowMarker: isShowMarker,
                );
              }
            }
          }
        }
      }
    }
  }

  void _drawHighlightContour(
    Canvas canvas,
    DrawableLayer drawableLayer,
    SimpleMapController controller,
  ) {
    final highlight = controller.highlight;

    final color = MapTheme.getContourColor(
      drawableLayer.layer.theme,
      drawableLayer.layer.highlightTheme,
    );

    if (color != null) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = controller.contourThickness / controller.scale
        ..isAntiAlias = true;

      if (highlight is MapSingleHighlight) {
        DrawableFeature? drawableFeature = highlight.drawableFeature;
        Drawable? drawable = drawableFeature?.drawable;
        if (drawable != null && drawable.visible) {
          drawable.drawOn(canvas, paint, controller.scale);
        }
      } else {
        DrawUtils.drawHighlight(
          canvas: canvas,
          drawableLayer: drawableLayer,
          paint: paint,
          scale: controller.scale,
          fillOnly: false,
          highlight: highlight!,
        );
      }
    }
  }

  void _drawLabel({
    required int index,
    required Canvas canvas,
    required MapFeature feature,
    required Drawable drawable,
    required Color featureColor,
    LabelStyleBuilder? labelStyleBuilder,
    bool isShowBackground = false,
    BackgroundLabelBuilder? backgroundLabelBuilder,
    LabelMarginBuilder? labelMarginBuilder,
    LabelBuilder? labelBuilder,
    bool modifiedCenter = true,
    bool isShowMarker = false,
  }) {
    final labelColor = _labelColorFrom(featureColor);

    TextStyle? labelStyle;
    if (labelStyleBuilder != null) {
      labelStyle = labelStyleBuilder(feature, featureColor, labelColor);
    }

    String? text = labelBuilder?.call(feature);
    if (text == null || text.trim().isEmpty) {
      text = feature.label!;
    }

    labelStyle ??= TextStyle(
      color: labelColor,
      fontSize: 11,
    );

    final bounds = MatrixUtils.transformRect(
      controller.worldToCanvas,
      drawable.getBounds(),
    );

    final backgroundStyle =
        backgroundLabelBuilder?.call(feature) ?? const BackgroundLabelStyle();

    final marginOffset = labelMarginBuilder?.call(feature);

    _drawText(
      index,
      canvas,
      modifiedCenter ? bounds.centerRight : bounds.center,
      text,
      labelStyle,
      isShowBackground: isShowBackground,
      backgroundStyle: backgroundStyle,
      margin: marginOffset,
      feature: feature,
      modifiedCenter: modifiedCenter,
      isShowMarker: isShowMarker,
    );
  }

  Color _labelColorFrom(Color featureColor) {
    final luminance = featureColor.computeLuminance();
    if (luminance > 0.55) {
      return const Color(0xFF000000);
    }
    return const Color(0xFFFFFFFF);
  }

  void _drawText(
    int index,
    Canvas canvas,
    Offset center,
    String text,
    TextStyle textStyle, {
    bool isShowBackground = false,
    BackgroundLabelStyle backgroundStyle = const BackgroundLabelStyle(),
    Offset? margin,
    required MapFeature feature,
    bool modifiedCenter = true,
    bool isShowMarker = false,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(minWidth: 0);

    final textWidth = textPainter.width;
    final textHeight = textPainter.height;

    double xCenter = center.dx -
        (modifiedCenter
            ? (textWidth < 50
                ? textWidth / 2
                : textWidth < 100
                    ? textWidth / 4
                    : 0)
            : (textWidth / 2));

    double yCenter = center.dy - (textHeight / 2);

    if (margin != null) {
      xCenter += margin.dx;
      yCenter += margin.dy;
    }

    if (isShowBackground) {
      _drawBackgroundText(
        index,
        canvas,
        Size(
          textPainter.width,
          textPainter.height,
        ),
        Offset(xCenter, yCenter),
        backgroundStyle,
        feature,
      );
    }

    textPainter.paint(canvas, Offset(xCenter, yCenter));

    if (isShowMarker) {
      _drawMarker(
        canvas,
        const Size(MARKER_WIDTH, (MARKER_WIDTH * 1.3214285714285714)),
        Offset(
          xCenter + MARKER_WIDTH / 2,
          yCenter - (MARKER_WIDTH + 8),
        ),
      );
    }
  }

  void _drawMarker(Canvas canvas, Size size, Offset offset) {
    final xCenter = offset.dx;
    final yCenter = offset.dy;

    Path path = Path();

    path.moveTo(
      size.width * 0.1466407 + xCenter,
      size.height * 0.1099805 + yCenter,
    );

    path.cubicTo(
      size.width * 0.2403711 + xCenter,
      size.height * 0.03968297 + yCenter,
      size.width * 0.3674464 + xCenter,
      size.height * 0.0001318770 + yCenter,
      size.width * 0.5000000 + xCenter,
      yCenter,
    );

    path.cubicTo(
      size.width * 0.6325536 + xCenter,
      size.height * 0.0001318770 + yCenter,
      size.width * 0.7596286 + xCenter,
      size.height * 0.03968297 + yCenter,
      size.width * 0.8533607 + xCenter,
      size.height * 0.1099805 + yCenter,
    );

    path.cubicTo(
      size.width * 0.9470893 + xCenter,
      size.height * 0.1802781 + yCenter,
      size.width * 0.9998250 + xCenter,
      size.height * 0.2755838 + yCenter,
      size.width + xCenter,
      size.height * 0.3750000 + yCenter,
    );

    path.cubicTo(
      size.width + xCenter,
      size.height * 0.6442189 + yCenter,
      size.width * 0.5341679 + xCenter,
      size.height * 0.9814054 + yCenter,
      size.width * 0.5143750 + xCenter,
      size.height * 0.9956243 + yCenter,
    );

    path.cubicTo(
      size.width * 0.5105250 + xCenter,
      size.height * 0.9984297 + yCenter,
      size.width * 0.5053679 + xCenter,
      size.height + yCenter,
      size.width * 0.5000000 + xCenter,
      size.height + yCenter,
    );
    path.cubicTo(
      size.width * 0.4946321 + xCenter,
      size.height + yCenter,
      size.width * 0.4894750 + xCenter,
      size.height * 0.9984297 + yCenter,
      size.width * 0.4856250 + xCenter,
      size.height * 0.9956243 + yCenter,
    );

    path.cubicTo(
      size.width * 0.4658321 + xCenter,
      size.height * 0.9814054 + yCenter,
      xCenter,
      size.height * 0.6442189 + yCenter,
      xCenter,
      size.height * 0.3750000 + yCenter,
    );

    path.cubicTo(
      size.width * 0.0001758364 + xCenter,
      size.height * 0.2755838 + yCenter,
      size.width * 0.05291071 + xCenter,
      size.height * 0.1802781 + yCenter,
      size.width * 0.1466407 + xCenter,
      size.height * 0.1099805 + yCenter,
    );

    path.close();

    Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xffECB06E);

    canvas.drawPath(path, paint);

    Path path_1 = Path();

    path_1.moveTo(
      size.width * 0.6428571 + xCenter,
      size.height * 0.5675703 + yCenter,
    );
    path_1.lineTo(
      size.width * 0.3571429 + xCenter,
      size.height * 0.5675703 + yCenter,
    );
    path_1.cubicTo(
      size.width * 0.3176904 + xCenter,
      size.height * 0.5675703 + yCenter,
      size.width * 0.2857143 + xCenter,
      size.height * 0.5433703 + yCenter,
      size.width * 0.2857143 + xCenter,
      size.height * 0.5135162 + yCenter,
    );
    path_1.lineTo(
      size.width * 0.2857143 + xCenter,
      size.height * 0.3153162 + yCenter,
    );
    path_1.lineTo(
      size.width * 0.7142857 + xCenter,
      size.height * 0.3153162 + yCenter,
    );
    path_1.lineTo(
      size.width * 0.7142857 + xCenter,
      size.height * 0.5135162 + yCenter,
    );
    path_1.cubicTo(
      size.width * 0.7142857 + xCenter,
      size.height * 0.5433703 + yCenter,
      size.width * 0.6823107 + xCenter,
      size.height * 0.5675703 + yCenter,
      size.width * 0.6428571 + xCenter,
      size.height * 0.5675703 + yCenter,
    );

    path_1.close();

    Paint paint_1 = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF195A53).withOpacity(0.35);

    canvas.drawPath(path_1, paint_1);

    Path path_2 = Path();
    path_2.moveTo(
      size.width * 0.4285714 + xCenter,
      size.height * 0.4954973 + yCenter,
    );
    path_2.lineTo(
      size.width * 0.3809536 + xCenter,
      size.height * 0.4954973 + yCenter,
    );
    path_2.cubicTo(
      size.width * 0.3678107 + xCenter,
      size.height * 0.4954973 + yCenter,
      size.width * 0.3571429 + xCenter,
      size.height * 0.4874243 + yCenter,
      size.width * 0.3571429 + xCenter,
      size.height * 0.4774784 + yCenter,
    );
    path_2.lineTo(
      size.width * 0.3571429 + xCenter,
      size.height * 0.4414432 + yCenter,
    );
    path_2.cubicTo(
      size.width * 0.3571429 + xCenter,
      size.height * 0.4314973 + yCenter,
      size.width * 0.3678107 + xCenter,
      size.height * 0.4234243 + yCenter,
      size.width * 0.3809536 + xCenter,
      size.height * 0.4234243 + yCenter,
    );
    path_2.lineTo(
      size.width * 0.4285714 + xCenter,
      size.height * 0.4234243 + yCenter,
    );
    path_2.cubicTo(
      size.width * 0.4417143 + xCenter,
      size.height * 0.4234243 + yCenter,
      size.width * 0.4523821 + xCenter,
      size.height * 0.4314973 + yCenter,
      size.width * 0.4523821 + xCenter,
      size.height * 0.441443 + yCenter,
    );
    path_2.lineTo(
      size.width * 0.4523821 + xCenter,
      size.height * 0.4774784 + yCenter,
    );
    path_2.cubicTo(
      size.width * 0.4523821 + xCenter,
      size.height * 0.4874243 + yCenter,
      size.width * 0.4417143 + xCenter,
      size.height * 0.4954973 + yCenter,
      size.width * 0.4285714 + xCenter,
      size.height * 0.4954973 + yCenter,
    );
    path_2.close();

    Paint paint_2 = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF195A53);

    canvas.drawPath(path_2, paint_2);

    Path path_3 = Path();
    path_3.moveTo(
      size.width * 0.7355964 + xCenter,
      size.height * 0.3432973 + yCenter,
    );
    path_3.lineTo(
      size.width * 0.7142893 + xCenter,
      size.height * 0.3110622 + yCenter,
    );
    path_3.lineTo(
      size.width * 0.7142893 + xCenter,
      size.height * 0.2972973 + yCenter,
    );
    path_3.cubicTo(
      size.width * 0.7142893 + xCenter,
      size.height * 0.2674414 + yCenter,
      size.width * 0.6823107 + xCenter,
      size.height * 0.2432432 + yCenter,
      size.width * 0.6428607 + xCenter,
      size.height * 0.2432432 + yCenter,
    );
    path_3.lineTo(
      size.width * 0.3571464 + xCenter,
      size.height * 0.2432432 + yCenter,
    );
    path_3.cubicTo(
      size.width * 0.3176932 + xCenter,
      size.height * 0.2432432 + yCenter,
      size.width * 0.2857168 + xCenter,
      size.height * 0.2674414 + yCenter,
      size.width * 0.2857168 + xCenter,
      size.height * 0.2972973 + yCenter,
    );
    path_3.lineTo(
      size.width * 0.2857168 + xCenter,
      size.height * 0.3110622 + yCenter,
    );
    path_3.lineTo(
      size.width * 0.2644075 + xCenter,
      size.height * 0.3432973 + yCenter,
    );
    path_3.cubicTo(
      size.width * 0.2595979 + xCenter,
      size.height * 0.3505757 + yCenter,
      size.width * 0.2618361 + xCenter,
      size.height * 0.3593703 + yCenter,
      size.width * 0.2698596 + xCenter,
      size.height * 0.3647919 + yCenter,
    );
    path_3.cubicTo(
      size.width * 0.2732882 + xCenter,
      size.height * 0.3671000 + yCenter,
      size.width * 0.3044550 + xCenter,
      size.height * 0.3873865 + yCenter,
      size.width * 0.3452407 + xCenter,
      size.height * 0.3873865 + yCenter,
    );
    path_3.cubicTo(
      size.width * 0.3716214 + xCenter,
      size.height * 0.3873865 + yCenter,
      size.width * 0.3940036 + xCenter,
      size.height * 0.3788838 + yCenter,
      size.width * 0.4074321 + xCenter,
      size.height * 0.3722703 + yCenter,
    );
    path_3.cubicTo(
      size.width * 0.4258821 + xCenter,
      size.height * 0.3782892 + yCenter,
      size.width * 0.4602893 + xCenter,
      size.height * 0.3873865 + yCenter,
      size.width * 0.5000036 + xCenter,
      size.height * 0.3873865 + yCenter,
    );
    path_3.cubicTo(
      size.width * 0.5397179 + xCenter,
      size.height * 0.3873865 + yCenter,
      size.width * 0.5741214 + xCenter,
      size.height * 0.3782892 + yCenter,
      size.width * 0.5925750 + xCenter,
      size.height * 0.3722703 + yCenter,
    );
    path_3.cubicTo(
      size.width * 0.6060036 + xCenter,
      size.height * 0.3788838 + yCenter,
      size.width * 0.6283821 + xCenter,
      size.height * 0.3873865 + yCenter,
      size.width * 0.6547643 + xCenter,
      size.height * 0.3873865 + yCenter,
    );
    path_3.cubicTo(
      size.width * 0.6955500 + xCenter,
      size.height * 0.3873865 + yCenter,
      size.width * 0.7267179 + xCenter,
      size.height * 0.3671000 + yCenter,
      size.width * 0.7301464 + xCenter,
      size.height * 0.3647919 + yCenter,
    );
    path_3.cubicTo(
      size.width * 0.7381679 + xCenter,
      size.height * 0.3593703 + yCenter,
      size.width * 0.7404071 + xCenter,
      size.height * 0.3505757 + yCenter,
      size.width * 0.7355964 + xCenter,
      size.height * 0.3432973 + yCenter,
    );

    path_3.close();

    canvas.drawPath(path_3, paint_2);

    Path path_4 = Path();
    path_4.moveTo(
      size.width * 0.6785714 + xCenter,
      size.height * 0.4234243 + yCenter,
    );
    path_4.cubicTo(
      size.width * 0.6194036 + xCenter,
      size.height * 0.4234243 + yCenter,
      size.width * 0.5714286 + xCenter,
      size.height * 0.4597324 + yCenter,
      size.width * 0.5714286 + xCenter,
      size.height * 0.5045054 + yCenter,
    );
    path_4.cubicTo(
      size.width * 0.5714286 + xCenter,
      size.height * 0.5054622 + yCenter,
      size.width * 0.5716679 + xCenter,
      size.height * 0.5064162 + yCenter,
      size.width * 0.5717143 + xCenter,
      size.height * 0.5073703 + yCenter,
    );
    path_4.cubicTo(
      size.width * 0.5739750 + xCenter,
      size.height * 0.5518216 + yCenter,
      size.width * 0.6279036 + xCenter,
      size.height * 0.5944514 + yCenter,
      size.width * 0.6582607 + xCenter,
      size.height * 0.6150297 + yCenter,
    );
    path_4.cubicTo(
      size.width * 0.6698821 + xCenter,
      size.height * 0.6229027 + yCenter,
      size.width * 0.6872393 + xCenter,
      size.height * 0.6229027 + yCenter,
      size.width * 0.6988571 + xCenter,
      size.height * 0.6150297 + yCenter,
    );
    path_4.cubicTo(
      size.width * 0.7292143 + xCenter,
      size.height * 0.5944514 + yCenter,
      size.width * 0.7831429 + xCenter,
      size.height * 0.5518405 + yCenter,
      size.width * 0.7854036 + xCenter,
      size.height * 0.5073703 + yCenter,
    );
    path_4.cubicTo(
      size.width * 0.7854750 + xCenter,
      size.height * 0.5064162 + yCenter,
      size.width * 0.7857143 + xCenter,
      size.height * 0.5054622 + yCenter,
      size.width * 0.7857143 + xCenter,
      size.height * 0.5045054 + yCenter,
    );
    path_4.cubicTo(
      size.width * 0.7857143 + xCenter,
      size.height * 0.4597324 + yCenter,
      size.width * 0.7377393 + xCenter,
      size.height * 0.4234243 + yCenter,
      size.width * 0.6785714 + xCenter,
      size.height * 0.4234243 + yCenter,
    );

    path_4.close();

    path_4.moveTo(
      size.width * 0.6785714 + xCenter,
      size.height * 0.5315324 + yCenter,
    );
    path_4.cubicTo(
      size.width * 0.6588571 + xCenter,
      size.height * 0.5315324 + yCenter,
      size.width * 0.6428571 + xCenter,
      size.height * 0.5194432 + yCenter,
      size.width * 0.6428571 + xCenter,
      size.height * 0.5045054 + yCenter,
    );
    path_4.cubicTo(
      size.width * 0.6428571 + xCenter,
      size.height * 0.4895703 + yCenter,
      size.width * 0.6588571 + xCenter,
      size.height * 0.4774784 + yCenter,
      size.width * 0.6785714 + xCenter,
      size.height * 0.4774784 + yCenter,
    );
    path_4.cubicTo(
      size.width * 0.6982857 + xCenter,
      size.height * 0.4774784 + yCenter,
      size.width * 0.7142857 + xCenter,
      size.height * 0.4895865 + yCenter,
      size.width * 0.7142857 + xCenter,
      size.height * 0.5045054 + yCenter,
    );
    path_4.cubicTo(
      size.width * 0.7142857 + xCenter,
      size.height * 0.5194243 + yCenter,
      size.width * 0.6982857 + xCenter,
      size.height * 0.5315324 + yCenter,
      size.width * 0.6785714 + xCenter,
      size.height * 0.5315324 + yCenter,
    );
    path_4.close();

    canvas.drawPath(path_4, paint_2);
  }

  void _drawBackgroundText(int index, Canvas canvas, Size size, Offset offset,
      BackgroundLabelStyle style, MapFeature feature) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = style.color;

    final verticalPadding = style.verticalPadding;
    final horizontalPadding = style.horizontalPadding;

    final rect = Rect.fromLTWH(
      offset.dx - horizontalPadding,
      offset.dy - verticalPadding,
      size.width + (horizontalPadding * 2),
      size.height + (verticalPadding * 2),
    );

    controller.addBgRect(
      data: DrawableLabelData(rect: rect, mapFeature: feature),
      id: index,
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: style.radius,
        topRight: style.radius,
        bottomLeft: style.radius,
        bottomRight: style.radius,
      ),
      paint,
    );

    Path path = Path();

    final startX = offset.dx + 2;
    final startY = offset.dy + size.height + verticalPadding / 2;
    path.moveTo(startX, startY);
    path.lineTo(startX + style.arrowRadius, startY + style.arrowRadius);
    path.lineTo(startX + style.arrowRadius * 2, startY);
    path.lineTo(startX, startY);

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
