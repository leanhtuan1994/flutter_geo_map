/// Generic [SimpleMap] error
class SimpleMapError extends Error {
  final String _message;

  SimpleMapError(this._message);

  SimpleMapError.keyNotFound(String key) : _message = 'Key "$key" not found.';

  SimpleMapError.invalidType(String type)
      : _message =
            'Invalid "$type" type. Must be: FeatureCollection, GeometryCollection, Feature, Point, MultiPoint, LineString, MultiLineString, Polygon or MultiPolygon.';

  SimpleMapError.invalidGeometryType(String type)
      : _message =
            'Invalid geometry "$type" type. Must be: GeometryCollection, Point, MultiPoint, LineString, MultiLineString, Polygon or MultiPolygon.';

  @override
  String toString() {
    return 'SimpleMapError - $_message';
  }
}
