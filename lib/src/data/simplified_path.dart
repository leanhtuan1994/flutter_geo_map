import 'dart:ui';

import 'package:equatable/equatable.dart';

/// Stores a simplified path generated from the original [MapFeature] geometry.
class SimplifiedPath extends Equatable {
  const SimplifiedPath(this.path, this.pointsCount);

  final Path path;
  final int pointsCount;

  @override
  List<Object?> get props => [path, pointsCount];
}
