// ignore_for_file: must_be_immutable

import 'package:equatable/equatable.dart';

import '../data/map_feature.dart';
import 'drawable.dart';

class DrawableFeature extends Equatable {
  DrawableFeature(this.feature);

  final MapFeature feature;
  Drawable? drawable;

  @override
  List<Object?> get props => [feature];
}
