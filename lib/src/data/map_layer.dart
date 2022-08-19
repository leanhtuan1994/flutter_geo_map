import 'dart:math';

import '../theme/map_highlight_theme.dart';
import '../theme/map_theme.dart';
import 'map_data_source.dart';

/// Layer for [VectorMap].
class MapLayer {
  MapLayer({
    required this.dataSource,
    int? id,
    MapTheme? theme,
    this.highlightTheme,
    this.name,
  })  : id = id ?? _randomId,
        theme = theme ?? MapTheme();

  final int id;
  final MapDataSource dataSource;
  final MapTheme theme;
  final MapHighlightTheme? highlightTheme;
  final String? name;

  /// Indicates if the hover is drawable, if there is any highlight theme and
  /// if it has a set value.
  bool get highlightDrawable {
    return highlightTheme?.hasValue ?? false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapLayer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Gets a random layer id.
  static int get _randomId {
    Random random = Random();
    return random.nextInt(9999999);
  }
}
