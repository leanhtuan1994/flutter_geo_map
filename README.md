# Flutter Geo Map

* Compatible with GeoJSON
* Multi resolution with geometry simplification
* Highly customizable
* High performance
* Interactable
* Pure Flutter (no WebView/JavaScript)

## Reading GeoJSON from String

Reading the geometries only.

```dart
  MapDataSource polygons = await MapDataSource.geoJson(geoJson: geoJson);
```

## Reading GeoJSON properties

The `keys` argument defines which properties must be loaded.
The `parseToNumber` argument defines which properties will have numeric values in quotes parsed to numbers.
The `labelKey` defines which property will be used to display its values as feature labels.
The `filterKey` & `filterValue` defines which property key will be used to filter json match value  

```dart
  MapDataSource polygons = await MapDataSource.geoJson(
      geoJson: geoJson,
      keys: ['Seq', 'Rnd'],
      parseToNumber: ['Rnd'],
      labelKey: 'Rnd',
      filterKet: 'Seq',
      filterValue '01');
```

## Creating the Widget

```dart
  SimpleMapController _controller = SimpleMapController();
```

```dart
  MapDataSource polygons = await MapDataSource.geoJson(geoJson: geoJson);
  MapLayer layer = MapLayer(dataSource: polygons);
  _controller.addLayer(layer);
```

```dart
  SimpleMap map = SimpleMap(controller: _controller);
```

## Theme

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapTheme(color: Colors.yellow, contourColor: Colors.red));
```

### Label visibility

```dart
  MapDataSource polygons =
      await MapDataSource.geoJson(geoJson: geoJson, labelKey: 'Name');
```

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapTheme(labelVisibility: (feature) => true));
```

Filter  label name to visible

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapTheme(labelVisibility: (feature) => feature.label == 'Darwin'));
```

### Label style

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapTheme(
          labelVisibility: (feature) => true,
          labelStyleBuilder: (feature, featureColor, labelColor) {
            if (feature.label == 'Darwin') {
              return TextStyle(
                color: labelColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              );
            }
            return TextStyle(
              color: labelColor,
              fontSize: 11,
            );
          }));
```

### Color by property value

Sets a color for each property value in GeoJSON. If a color is not set, the default color is used.

Mapping the property key:

```dart
  MapDataSource polygons = await MapDataSource.geoJson(
      geoJson: geoJson, keys: ['Seq'], labelKey: 'Seq');
```

Setting the colors for the property values:

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapValueTheme(
          contourColor: Colors.white,
          labelVisibility: (feature) => true,
          key: 'Seq',
          colors: {
            2: Colors.green,
            4: Colors.red,
            6: Colors.orange,
            8: Colors.blue
          }));
```

### Color by rule

The feature color is obtained from the first rule that returns a non-null color. If all rules return a null color, the default color is used.

Mapping the property key:

```dart
  MapDataSource polygons =
      await MapDataSource.geoJson(geoJson: geoJson, keys: ['Name', 'Seq']);
```

Setting the rules:

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapRuleTheme(contourColor: Colors.white, colorRules: [
        (feature) {
          String? value = feature.getValue('Name');
          return value == 'Faraday' ? Colors.red : null;
        },
        (feature) {
          double? value = feature.getDoubleValue('Seq');
          return value != null && value < 3 ? Colors.green : null;
        },
        (feature) {
          double? value = feature.getDoubleValue('Seq');
          return value != null && value > 9 ? Colors.blue : null;
        }
      ]));
```

### Gradient

The gradient is created given the colors and limit values of the chosen property.
The property must have numeric values.

#### Auto min/max values

Uses the min and max values read from data source.

```dart
  MapDataSource polygons = await MapDataSource.geoJson(
      geoJson: geoJson, keys: ['Seq'], labelKey: 'Seq');
```

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapGradientTheme(
          contourColor: Colors.white,
          labelVisibility: (feature) => true,
          key: 'Seq',
          colors: [Colors.blue, Colors.yellow, Colors.red]));
```

#### Setting min or max values manually

If the `min` value is set, all lower values will be displayed using the first gradient color.
If the `max` value is set, all higher values will be displayed using the last gradient color.

```dart
  MapDataSource polygons = await MapDataSource.geoJson(
      geoJson: geoJson, keys: ['Seq'], labelKey: 'Seq');
```

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapGradientTheme(
          contourColor: Colors.white,
          labelVisibility: (feature) => true,
          key: 'Seq',
          min: 3,
          max: 9,
          colors: [Colors.blue, Colors.yellow, Colors.red]));
```

## Highlight theme

Used by addons and cursor hover to highlight layer features on the map.

### Color

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      highlightTheme: MapHighlightTheme(color: Colors.green));
```

### Contour color

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      highlightTheme: MapHighlightTheme(contourColor: Colors.red));
```

### Label highlight

```dart
  MapDataSource polygons =
      await MapDataSource.geoJson(geoJson: geoJson, labelKey: 'Name');
```

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      highlightTheme: MapHighlightTheme(labelVisibility: (feature) => true));
```

## Contour thickness

```dart
  SimpleMapController _controller = SimpleMapController(contourThickness: 3);


```

## Cursor hover rule

### Enabling hover by property value

```dart
  MapDataSource polygons =
      await MapDataSource.geoJson(geoJson: geoJson, keys: ['Seq']);
```

```dart
  // coloring only the 'Darwin' feature
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapValueTheme(key: 'Seq', colors: {4: Colors.green}),
      highlightTheme: MapHighlightTheme(color: Colors.green[900]!));
```

```dart
  // enabling hover only for the 'Darwin' feature
  SimpleMap map = SimpleMap(
      controller: _controller,
      hoverRule: (feature) {
        return feature.getValue('Seq') == 4;
      });
```

## Cursor hover listener

```dart
  SimpleMap map = SimpleMap(
      controller: _controller,
      hoverListener: (MapFeature? feature) {
        if (feature != null) {
          int id = feature.id;
        }
      });
```

## Layers

```dart
  MapHighlightTheme highlightTheme = MapHighlightTheme(color: Colors.green);

  MapDataSource polygons =
      await MapDataSource.geoJson(geoJson: polygonsGeoJson);
  MapLayer polygonLayer =
      MapLayer(dataSource: polygons, highlightTheme: highlightTheme);
  _controller.addLayer(polygonLayer);

  MapDataSource points = await MapDataSource.geoJson(geoJson: pointsGeoJson);
  MapLayer pointsLayer = MapLayer(
      dataSource: points,
      theme: MapTheme(color: Colors.black),
      highlightTheme: highlightTheme);
  _controller.addLayer(pointsLayer);
```

### Overlay hover contour

Allows you to draw the contour over all layers

```dart
  MapDataSource dataSource1 = MapDataSource.geometries([
    MapPolygon.coordinates([2, 3, 4, 5, 6, 3, 4, 1, 2, 3])
  ]);
  MapDataSource dataSource2 = MapDataSource.geometries([
    MapPolygon.coordinates([0, 2, 2, 4, 4, 2, 2, 0, 0, 2]),
    MapPolygon.coordinates([4, 2, 6, 4, 8, 2, 6, 0, 4, 2])
  ]);
```

Overlay disabled:

```dart
  MapHighlightTheme highlightTheme =
      MapHighlightTheme(color: Colors.black, contourColor: Colors.black);

  MapLayer layer1 = MapLayer(
      dataSource: dataSource1,
      theme: MapTheme(color: Colors.yellow, contourColor: Colors.black),
      highlightTheme: highlightTheme);
  MapLayer layer2 = MapLayer(
      dataSource: dataSource2,
      theme: MapTheme(color: Colors.green, contourColor: Colors.black),
      highlightTheme: highlightTheme);

  _controller = SimpleMapController(layers: [layer1, layer2]);
```

Overlay enabled:

```dart
  MapLayer layer1 = MapLayer(
      dataSource: dataSource1,
      theme: MapTheme(color: Colors.yellow, contourColor: Colors.black),
      highlightTheme: MapHighlightTheme(
          color: Colors.black,
          contourColor: Colors.black,
          overlayContour: true));
  MapLayer layer2 = MapLayer(
      dataSource: dataSource2,
      theme: MapTheme(color: Colors.green, contourColor: Colors.black),
      highlightTheme:
          MapHighlightTheme(color: Colors.black, contourColor: Colors.black));

  _controller = SimpleMapController(layers: [layer1, layer2]);
```
