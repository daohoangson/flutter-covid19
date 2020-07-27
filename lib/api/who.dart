import 'dart:isolate';

import 'package:covid19/api/api.dart';
import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class WhoApi extends Api {
  static const CSV_URL = 'https://covid19.who.int/WHO-COVID-19-global-data.csv';

  WhoApi._() {
    if (kIsWeb) {
      /// [Isolate.spawn] is not supported in web
      compute(_compute, null).then(
          (data) => setData(
                countries: data.countries,
                worldLatest: data.worldLatest,
              ),
          onError: (reason) => error = reason);
    } else {
      final receivePort = ReceivePort();
      Isolate.spawn(_isolate, receivePort.sendPort);

      receivePort.listen((message) {
        if (message is _WhoData) {
          setData(
            countries: message.countries,
            worldLatest: message.worldLatest,
          );
        } else if (message is _WhoProgress) {
          progress = message.value;
        }
      }, onError: (reason) => error = reason);
    }
  }

  static Api _instance;
  static Api getInstance() {
    _instance ??= WhoApi._();
    return _instance;
  }
}

@immutable
class _WhoData {
  final List<ApiCountry> countries;
  final ApiRecord worldLatest;

  _WhoData({
    this.countries,
    this.worldLatest,
  });
}

@immutable
class _WhoProgress {
  final double value;
  _WhoProgress.downloading(int count, int total)
      : value = (count / (total ?? 1500000.0)).clamp(0, 1) * .5;
  _WhoProgress.parsing(Iterable<ApiCountry> countries)
      : value = 0.5 + (countries.length / 250).clamp(0, 1) * .5;
}

Future<_WhoData> _compute(_) async => _fetch();

void _isolate(SendPort sendPort) async {
  final data = await _fetch(sendPort: sendPort);
  sendPort.send(data);
}

Future<_WhoData> _fetch({SendPort sendPort}) async {
  final whoUrl = WhoApi.CSV_URL;
  final url = kIsWeb ? 'https://cors-anywhere.herokuapp.com/$whoUrl' : whoUrl;
  final response = await Dio().getUri<String>(
    Uri.parse(url),
    onReceiveProgress: (count, total) =>
        sendPort?.send(_WhoProgress.downloading(count, total)),
    options: Options(responseType: ResponseType.plain),
  );
  if (response.statusCode != 200) {
    return Future.error(StateError('WHO statusCode ${response.statusCode}'));
  }

  final data = const CsvToListConverter(
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(response.data);
  if (data.length < 10) {
    // something is wrong, we expect thousands of rows
    return Future.error(StateError('WHO data.length=${data.length}'));
  }

  final headers = data[0].map((s) => s.trim()).toList(growable: false);
  final fieldIndexDateReported = headers.indexOf('Date_reported');
  if (fieldIndexDateReported == -1) {
    return Future.error(StateError('WHO field `Date_reported` not found'));
  }
  final fieldIndexCountryCode = headers.indexOf('Country_code');
  if (fieldIndexCountryCode == -1) {
    return Future.error(StateError('WHO field `Country_code` not found'));
  }
  final fieldIndexCountry = headers.indexOf('Country');
  if (fieldIndexCountry == -1) {
    return Future.error(StateError('WHO field `Country` not found'));
  }
  final fieldIndexNewCases = headers.indexOf('New_cases');
  if (fieldIndexNewCases == -1) {
    return Future.error(StateError('WHO field `New_cases` not found'));
  }
  final fieldIndexCumulativeCases = headers.indexOf('Cumulative_cases');
  if (fieldIndexCumulativeCases == -1) {
    return Future.error(StateError('WHO field `Cumulative_cases` not found'));
  }
  final fieldIndexNewDeaths = headers.indexOf('New_deaths');
  if (fieldIndexNewDeaths == -1) {
    return Future.error(StateError('WHO field `New_deaths` not found'));
  }
  final fieldIndexCumulativeDeaths = headers.indexOf('Cumulative_deaths');
  if (fieldIndexCumulativeDeaths == -1) {
    return Future.error(StateError('WHO field `Cumulative_deaths` not found'));
  }

  var i = 1;
  DateTime latestDate;
  final list = List<ApiCountry>();
  final map = Map<String, int>();
  while (i < data.length) {
    final countryCode = data[i][fieldIndexCountryCode];
    if (!map.containsKey(countryCode)) {
      list.add(ApiCountry(
        countryCode,
        name: data[i][fieldIndexCountry],
      ));
      map[countryCode] = list.length - 1;

      sendPort?.send(_WhoProgress.parsing(list));
    }

    final dateReported = DateTime.tryParse(data[i][fieldIndexDateReported]);
    if (dateReported == null) {
      continue;
    }
    if (latestDate == null || latestDate.isBefore(dateReported)) {
      latestDate = dateReported;
    }

    list[map[countryCode]].records.add(ApiRecord(
          casesNew: int.tryParse(data[i][fieldIndexNewCases]) ?? 0,
          casesTotal: int.tryParse(data[i][fieldIndexCumulativeCases]) ?? 0,
          date: dateReported,
          deathsNew: int.tryParse(data[i][fieldIndexNewDeaths]) ?? 0,
          deathsTotal: int.tryParse(data[i][fieldIndexCumulativeDeaths]) ?? 0,
        ));

    i++;
  }

  final worldLatest = ApiRecord.from(list
      .map((country) => country.latest)
      .where((record) => record.date == latestDate));

  return _WhoData(
    countries: list,
    worldLatest: worldLatest,
  );
}
