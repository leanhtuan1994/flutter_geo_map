import 'dart:math';

import 'package:equatable/equatable.dart';

import '../theme/map_highlight_theme.dart';
import '../theme/map_theme.dart';
import 'map_data_source.dart';

/// Layer for [SimpleMap].
class MapLayer extends Equatable {
  MapLayer({
    required this.dataSource,
    int? id,
    MapTheme? theme,
    this.highlightTheme,
    this.name,
    this.contourThickness,
  })  : id = id ?? _randomId,
        theme = theme ?? MapTheme();

  final int id;
  final MapDataSource dataSource;
  final MapTheme theme;
  final MapHighlightTheme? highlightTheme;
  final String? name;
  final double? contourThickness;

  /// Indicates if the hover is drawable, if there is any highlight theme and
  /// if it has a set value.
  bool get highlightDrawable {
    return highlightTheme?.hasValue ?? false;
  }

  @override
  List<Object?> get props => [
        id,
        dataSource,
        theme,
        name,
        contourThickness,
      ];

  /// Gets a random layer id.
  static int get _randomId {
    Random random = Random();
    return random.nextInt(9999999);
  }
}
