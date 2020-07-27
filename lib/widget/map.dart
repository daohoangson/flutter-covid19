import 'package:covid19/api/dpl.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class MapWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GoogleMap(
        buildingsEnabled: false,
        compassEnabled: false,
        initialCameraPosition: CameraPosition(
          target: LatLng(14.058324, 108.277199),
        ),
        mapToolbarEnabled: false,
        myLocationButtonEnabled: false,
        myLocationEnabled: false,
        onMapCreated: (v) => MapData.of(context)._setController(v),
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        zoomControlsEnabled: false,
        zoomGesturesEnabled: false,
      );
}

class MapData extends ChangeNotifier {
  GoogleMapController _controller;
  void _setController(GoogleMapController v) {
    _controller = v;
    notifyListeners();
  }

  Future<void> animateCamera(String countryCode) async {
    if (!kDplCountriesCsv.containsKey(countryCode)) {
      return;
    }
    final latLng = kDplCountriesCsv[countryCode];
    final cameraUpdate = CameraUpdate.newLatLng(LatLng(latLng[0], latLng[1]));
    return _controller?.animateCamera(cameraUpdate);
  }

  static MapData of(BuildContext context) =>
      Provider.of<MapData>(context, listen: false);
}
