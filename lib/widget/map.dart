import 'dart:math';

import 'package:covid19/api/dpl.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:provider/provider.dart';

class MapWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Consumer<MapData>(
        builder: (_, data, __) => google.GoogleMap(
          buildingsEnabled: false,
          compassEnabled: false,
          heatmaps: data._heatmaps,
          initialCameraPosition: google.CameraPosition(
            target: _latLngFromCode('VN'),
          ),
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          onMapCreated: (v) => MapData.of(context)._setController(v),
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
        ),
      );
}

class MapData extends ChangeNotifier {
  google.GoogleMapController _controller;
  void _setController(google.GoogleMapController v) {
    _controller = v;
    notifyListeners();
  }

  Set<google.Heatmap> _heatmaps;
  set heatmap(Heatmap heatmap) {
    _heatmaps = Set()
      ..add(google.Heatmap(
        heatmapId: google.HeatmapId('default'),
        points: heatmap.points
            .map((p) {
              final latLng = _latLngFromCode(p.countryCode);
              if (latLng == null) return null;

              return google.WeightedLatLng(
                point: latLng,
                intensity: log(p.value).clamp(1, 20).ceil(),
              );
            })
            .where((p) => p != null)
            .toList(growable: false),
        radius: 20,
      ));
    notifyListeners();
  }

  Future<void> animateCamera(String countryCode) async {
    final latLng = _latLngFromCode(countryCode);
    if (latLng == null) return;

    final cameraUpdate = google.CameraUpdate.newLatLng(latLng);
    return _controller?.animateCamera(cameraUpdate);
  }

  static MapData of(BuildContext context) =>
      Provider.of<MapData>(context, listen: false);
}

class Heatmap {
  final Iterable<HeatmapPoint> points;

  Heatmap({@required this.points});
}

class HeatmapPoint {
  final String countryCode;
  final int value;

  HeatmapPoint({@required this.countryCode, @required this.value});
}

google.LatLng _latLngFromCode(String countryCode) {
  if (!kDplCountriesCsv.containsKey(countryCode)) {
    return null;
  }
  final values = kDplCountriesCsv[countryCode];
  return google.LatLng(values[0], values[1]);
}
