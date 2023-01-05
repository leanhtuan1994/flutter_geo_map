import 'package:example/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_simple_map/flutter_simple_map.dart';

import 'utils/assets.dart';

typedef FocusProvinceCallback = void Function(MapFeature feature);

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AfterLayoutMixin {
  late SimpleMapController _controller;

  @override
  void initState() {
    _controller = SimpleMapController(
      mode: SimpleMapMode.panAndZoom,
      contourThickness: 1,
      barrierDismissibleHighlight: false,
      delayToRefreshResolution: 500,
      maxScale: 30000,
    );

    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _loadGeoJson();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SimpleMap(
          controller: _controller,
          layersPadding: EdgeInsets.zero,
          onFeaturePress: (feature) {},
        ),
      ),
    );
  }

  void _loadGeoJson() async {
    String geoJson = await loadJsonData();

    MapDataSource vietnamCounties = await MapDataSource.geoJson(
      geoJson: geoJson,
      keys: ["GID_1", "NAME_1", "ID_1", "VARNAME_1"],
      labelKey: "NAME_1",
    );

    final layer = MapLayer(
      dataSource: vietnamCounties,
      theme: MapTheme(
        contourColor: Colors.white,
        color: Colors.green[900],
        labelVisibility: (feature) => false,
      ),
    );

    _controller.addLayer(layer);
  }

  Future<String> loadJsonData() async {
    return GeoJsonAsset.vietnam();
  }
}
