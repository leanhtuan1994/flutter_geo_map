import 'package:flutter/widgets.dart';

import '../../data/map_layer.dart';
import '../map_addon.dart';

/// Abstract legend
///
/// Allows customize [padding], [margin] and [decoration]
abstract class Legend extends MapAddon {
  /// Builds a legend
  Legend(
      {required this.layer,
      EdgeInsetsGeometry? padding,
      EdgeInsetsGeometry? margin,
      Decoration? decoration})
      : super(padding: padding, decoration: decoration, margin: margin);
  final MapLayer layer;
}
