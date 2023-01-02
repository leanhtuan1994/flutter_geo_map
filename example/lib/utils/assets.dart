import 'package:flutter/services.dart';

class JsonAssets {
  static const vietnam = 'assets/jsons/vietnam.json';
  static const vietnamDistricts = 'assets/jsons/vietnam_districts.json';
  static const vietnamXpi = 'assets/jsons/vietnam_xpi.json';
  static const vietnamXsp = 'assets/jsons/vietnam_xsp.json';
}

class GeoJsonAsset {
  static Future<String> vietnam() {
    return rootBundle.loadString(JsonAssets.vietnam);
  }

  static Future<String> vietnamXSP() {
    return rootBundle.loadString(JsonAssets.vietnamXsp);
  }

  static Future<String> vietnamXPI() {
    return rootBundle.loadString(JsonAssets.vietnamXpi);
  }

  static Future<String> vietNamDistricts() {
    return rootBundle.loadString(JsonAssets.vietnamDistricts);
  }
}
