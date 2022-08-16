// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'data/geometries.dart';
import 'data/map_feature.dart';
import 'error.dart';

enum GeometryType {
  Point,
  MultiPoint,
  LineString,
  MultiLineString,
  Polygon,
  MultiPolygon,
  Other;

  @override
  String toString() => name;
}

enum MapType {
  FeatureCollection,
  GeometryCollection,
  Feature,

  Other;

  @override
  String toString() => name;
}

class Keys {
  static const String TYPE = "type";
  static const String COORDINATES = "coordinates";
  static const String FEATURES = "features";
  static const String GEOMETRY = "geometry";
  static const String PROPERTIES = "properties";
}

/// Generic GeoJSON reader.
class _GeoJsonReaderBase {
  void _checkKeyOn(Map<String, dynamic> map, {required String key}) {
    if (map.containsKey(key) == false) {
      throw VectorMapError.keyNotFound(key);
    }
  }

  GeometryType _generateGeometryType(Map<String, dynamic> map) {
    final type = GeometryType.values.firstWhere(
      (e) => e.name == (map[Keys.TYPE] as String? ?? GeometryType.Other.name),
    );
    return type;
  }

  MapType _generateMapType(Map<String, dynamic> map) {
    final type = MapType.values.firstWhere(
      (e) => e.name == (map[Keys.TYPE] as String? ?? MapType.Other.name),
    );

    return type;
  }

  MapGeometry _readGeometry(
    Map<String, dynamic> map, {
    bool hasParent = false,
  }) {
    _checkKeyOn(map, key: Keys.TYPE);

    final type = _generateGeometryType(map);

    switch (type) {
      //TODO other geometries
      case GeometryType.Point:
        return _readPoint(map);
      case GeometryType.MultiPoint:
        throw UnimplementedError();
      case GeometryType.LineString:
        return _readLineString(map);
      case GeometryType.MultiLineString:
        return _readMultiLineString(map);
      case GeometryType.Polygon:
        return _readPolygon(map);
      case GeometryType.MultiPolygon:
        return _readMultiPolygon(map);
      default:
        if (hasParent) {
          throw VectorMapError.invalidGeometryType(type.name);
        } else {
          throw VectorMapError.invalidType(type.name);
        }
    }
  }

  MapGeometry _readPoint(Map<String, dynamic> map) {
    _checkKeyOn(map, key: Keys.COORDINATES);
    List coordinates = map[Keys.COORDINATES];
    if (coordinates.length == 2) {
      double x = _toDouble(coordinates[0]);
      double y = _toDouble(coordinates[1]);
      return MapPoint(x, y);
    }

    throw VectorMapError(
        'Expected 2 coordinates but received ' + coordinates.length.toString());
  }

  MapGeometry _readLineString(Map<String, dynamic> map) {
    _checkKeyOn(map, key: Keys.COORDINATES);
    List coordinates = map[Keys.COORDINATES];
    List<MapPoint> points = [];
    for (List xy in coordinates) {
      double x = _toDouble(xy[0]);
      double y = _toDouble(xy[1]);
      points.add(MapPoint(x, y));
    }
    return MapLineString(points);
  }

  MapGeometry _readMultiLineString(Map<String, dynamic> map) {
    _checkKeyOn(map, key: Keys.COORDINATES);
    List coordinates = map[Keys.COORDINATES];
    List<MapLineString> lineString = [];
    for (List coords in coordinates) {
      List<MapPoint> points = [];
      for (List xy in coords) {
        double x = _toDouble(xy[0]);
        double y = _toDouble(xy[1]);
        points.add(MapPoint(x, y));
      }
      lineString.add(MapLineString(points));
    }
    return MapMultiLineString(lineString);
  }

  MapGeometry _readPolygon(Map<String, dynamic> map) {
    late MapLinearRing externalRing;
    List<MapLinearRing> internalRings = [];

    _checkKeyOn(map, key: Keys.COORDINATES);
    List rings = map[Keys.COORDINATES];
    for (int i = 0; i < rings.length; i++) {
      List<MapPoint> points = [];
      List ring = rings[i];
      for (List xy in ring) {
        double x = _toDouble(xy[0]);
        double y = _toDouble(xy[1]);
        points.add(MapPoint(x, y));
      }
      if (i == 0) {
        externalRing = MapLinearRing(points);
      } else {
        internalRings.add(MapLinearRing(points));
      }
    }

    return MapPolygon(externalRing, internalRings);
  }

  MapGeometry _readMultiPolygon(Map<String, dynamic> map) {
    _checkKeyOn(map, key: Keys.COORDINATES);
    List polygons = map[Keys.COORDINATES];

    List<MapPolygon> mapPolygons = [];
    for (List rings in polygons) {
      late MapLinearRing externalRing;
      List<MapLinearRing> internalRings = [];

      for (int i = 0; i < rings.length; i++) {
        List<MapPoint> points = [];
        List ring = rings[i];
        for (List xy in ring) {
          double x = _toDouble(xy[0]);
          double y = _toDouble(xy[1]);
          points.add(MapPoint(x, y));
        }
        if (i == 0) {
          externalRing = MapLinearRing(points);
        } else {
          internalRings.add(MapLinearRing(points));
        }
      }
      MapPolygon polygon = MapPolygon(externalRing, internalRings);
      mapPolygons.add(polygon);
    }

    return MapMultiPolygon(mapPolygons);
  }

  /// Parses a dynamic coordinate to [double].
  double _toDouble(dynamic coordinate) {
    if (coordinate is double) {
      return coordinate;
    } else if (coordinate is int) {
      return coordinate.toDouble();
    }
    // The coordinate shouldn't be a String but since it is, tries to parse.
    return double.parse(coordinate.toString());
  }
}

enum ColorValueFormat { hex }

/// Properties read.
class _Properties {
  _Properties({this.label, this.values});

  /// Label value extracted from [labelKey].
  final String? label;
  final Map<String, dynamic>? values;
}

/// [MapFeature] reader
///
/// The [keys] argument defines which properties must be loaded.
/// The [parseToNumber] argument defines which properties will have numeric
/// values in quotes parsed to numbers.
class MapFeatureReader extends _GeoJsonReaderBase {
  MapFeatureReader({
    this.labelKey,
    this.keys,
    this.parseToNumber,
    this.colorKey,
    this.colorValueFormat = ColorValueFormat.hex,
  });

  final List<MapFeature> _list = [];

  final String? labelKey;
  final Set<String>? keys;
  final Set<String>? parseToNumber;
  final String? colorKey;
  final ColorValueFormat colorValueFormat;

  Future<List<MapFeature>> read(String geoJson) async {
    Map<String, dynamic> map = json.decode(geoJson);
    await _readMap(map);
    return _list;
  }

  Future<void> _readMap(Map<String, dynamic> map) async {
    _checkKeyOn(map, key: Keys.TYPE);

    final type = _generateMapType(map);

    switch (type) {
      case MapType.FeatureCollection:
        _checkKeyOn(map, key: Keys.FEATURES);
        //TODO check if it is a Map?
        for (Map<String, dynamic> featureMap in map[Keys.FEATURES]) {
          _readFeature(featureMap);
        }
        break;
      case MapType.GeometryCollection:
        //TODO handle geometry collection type
        break;
      case MapType.Feature:
        _readFeature(map);
        break;

      default:
        MapGeometry geometry = _readGeometry(map);
        _addFeature(geometry: geometry);
        break;
    }
  }

  void _readFeature(Map<String, dynamic> map) {
    _checkKeyOn(map, key: Keys.GEOMETRY);
    Map<String, dynamic> geometryMap = map[Keys.GEOMETRY];
    MapGeometry geometry = _readGeometry(geometryMap, hasParent: true);
    _Properties? properties;
    if ((labelKey != null || keys != null || colorKey != null) &&
        map.containsKey(Keys.PROPERTIES)) {
      Map<String, dynamic> propertiesMap = map[Keys.PROPERTIES];
      properties = _readProperties(propertiesMap);
    }
    _addFeature(geometry: geometry, properties: properties);
  }

  _Properties _readProperties(Map<String, dynamic> map) {
    String? label;
    Map<String, dynamic>? values;
    if (labelKey != null && map.containsKey(labelKey)) {
      // converting dynamic to String
      label = map[labelKey].toString();
    }
    if (keys != null) {
      if (keys!.isNotEmpty) {
        Map<String, dynamic> valuesTmp = <String, dynamic>{};
        for (String key in keys!) {
          if (map.containsKey(key)) {
            dynamic value = map[key];
            if (parseToNumber != null &&
                parseToNumber!.contains(key) &&
                value is String) {
              value = double.parse(value);
            }
            valuesTmp[key] = value;
          }
        }
        if (valuesTmp.isNotEmpty) {
          values = valuesTmp;
        }
      }
    }
    return _Properties(label: label, values: values);
  }

  void _addFeature({required MapGeometry geometry, _Properties? properties}) {
    _list.add(
      MapFeature(
          id: _list.length + 1,
          geometry: geometry,
          properties: properties?.values,
          label: properties?.label),
    );
  }
}

/// GeoJSON geometry reader.
class MapGeometryReader extends _GeoJsonReaderBase {
  final List<MapGeometry> _list = [];

  Future<List<MapGeometry>> geoJson(String geoJson) async {
    Map<String, dynamic> map = json.decode(geoJson);
    await _readMap(map);
    return _list;
  }

  Future<void> _readMap(Map<String, dynamic> map) async {
    _checkKeyOn(map, key: Keys.TYPE);

    final type = _generateMapType(map);

    switch (type) {
      case MapType.FeatureCollection:
        _checkKeyOn(map, key: Keys.FEATURES);
        for (Map<String, dynamic> featureMap in map[Keys.FEATURES]) {
          _readFeature(featureMap);
        }
        break;
      case MapType.GeometryCollection:
        //TODO handle geometry collection type
        break;
      case MapType.Feature:
        _readFeature(map);
        break;
      default:
        MapGeometry geometry = _readGeometry(map);
        _list.add(geometry);
        break;
    }
  }

  void _readFeature(Map<String, dynamic> map) {
    _checkKeyOn(map, key: Keys.GEOMETRY);
    Map<String, dynamic> geometryMap = map[Keys.GEOMETRY];
    MapGeometry geometry = _readGeometry(geometryMap, hasParent: true);
    _list.add(geometry);
  }
}
