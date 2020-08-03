import 'package:covid19/data/ipdata/api_key.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class Ipdata extends ChangeNotifier {
  Ipdata() {
    Dio()
        .getUri<Map>(
      Uri.https(
        'api.ipdata.co',
        '',
        {'api-key': kApiKey},
      ),
      options: Options(responseType: ResponseType.json),
    )
        .then(
      (value) {
        final map = value.data;
        if (map.containsKey('country_code')) _countryCode = map['country_code'];
        if (map.containsKey('ip')) _ip = map['ip'];

        if (map.containsKey('city') && map.containsKey('country_name'))
          _title = "${map['city']}, ${map['country_name']}";
      },
      onError: (reason) => _error = "$reason",
    ).whenComplete(() {
      _isLoading = false;
      notifyListeners();
    });
  }

  String _countryCode;
  String get countryCode => _countryCode;

  String _error;
  String get error => _error;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _ip;
  String get ip => _ip;

  String _title;
  String get title => _title;
}
