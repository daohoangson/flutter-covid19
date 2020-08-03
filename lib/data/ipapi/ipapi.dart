import 'package:covid19/data/ipapi/api_key.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class IpApi extends ChangeNotifier {
  IpApi() {
    // TODO: use HTTPS
    final uri = Uri.http(
      'api.ipapi.com',
      'api/check',
      {'access_key': kIpApiKey},
    );
    Dio()
        .getUri<Map>(
      uri,
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
      onError: (reason) => print(reason),
    ).whenComplete(() {
      _isLoading = false;
      notifyListeners();
    });
  }

  String _countryCode;
  String get countryCode => _countryCode;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _ip;
  String get ip => _ip;

  String _title;
  String get title => _title;
}
