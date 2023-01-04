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

/// Painter for [SimpleMap].
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

              if (highlight != null &&
                  highlight.layerId == layer.id &&
                  highlight.applies(feature) &&
                  highlightTheme != null &&
                  highlightTheme.labelVisibility != null) {
                labelVisibility = highlightTheme.labelVisibility;
                backgroundVisibility = highlightTheme.backgroundLabelVisibility;
              } else {
                labelVisibility = theme.labelVisibility;
                backgroundVisibility = theme.backgroundLabelVisibility;
              }

              backgroundVisibility ??= theme.backgroundLabelVisibility;

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

                bool hasLabelBg = false;

                if (backgroundVisibility != null &&
                    backgroundVisibility(feature)) {
                  hasLabelBg = true;
                }

                _drawLabel(
                  index: index,
                  canvas: canvas,
                  feature: feature,
                  drawable: drawable,
                  featureColor: featureColor,
                  labelStyleBuilder: labelStyleBuilder,
                  isShowBackground: hasLabelBg,
                  backgroundLabelBuilder: backgroundLabelBuilder,
                  labelMarginBuilder: labelMarginBuilder,
                  labelBuilder: labelBuilder,
                  modifiedCenter: modifiedCenter,
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
  }) {
    final labelColor = _labelColorFrom(featureColor);

    TextStyle? labelStyle;
    if (labelStyleBuilder != null) {
      labelStyle = labelStyleBuilder(feature, featureColor, labelColor);
    }

    String? text = labelBuilder?.call(feature);

    if (text?.trim().isEmpty ?? false) {
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
      text!,
      labelStyle,
      isShowBackground: isShowBackground,
      backgroundStyle: backgroundStyle,
      margin: marginOffset,
      feature: feature,
      modifiedCenter: modifiedCenter,
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
