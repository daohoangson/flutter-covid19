import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WhoApi extends ChangeNotifier {
  WhoApi._() {
    compute(
      _fetch,
      'https://covid19.who.int/WHO-COVID-19-global-data.csv',
    ).then(
      (value) => countries = value,
      onError: (reason) => error = reason,
    );
  }

  List<WhoCountry> _countries;
  List<WhoCountry> get countries => _countries;
  set countries(List<WhoCountry> v) {
    _countries = v;
    _isLoading = false;
    notifyListeners();
  }

  Error _error;
  Error get error => _error;
  set error(Error v) {
    _error = v;
    _isLoading = false;
    notifyListeners();
  }

  bool get hasData => !_isLoading && _countries != null;

  bool get hasError => !_isLoading && _error != null;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  static WhoApi _instance;
  static WhoApi getInstance() {
    _instance ??= WhoApi._();
    return _instance;
  }

  static Future<Iterable<WhoCountry>> _fetch(String whoUrl) async {
    final url = kIsWeb ? 'https://cors-anywhere.herokuapp.com/$whoUrl' : whoUrl;
    final response = await http.get(url);
    if (response.statusCode != 200) {
      return Future.error(
          StateError('response.statusCode=${response.statusCode}'));
    }

    final data = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(response.body);
    if (data.length < 10) {
      // something is wrong, we expect thousands of rows
      return Future.error(StateError('data.length=${data.length}'));
    }

    final headers = data[0].map((s) => s.trim()).toList(growable: false);
    final fieldIndexDateReported = headers.indexOf('Date_reported');
    if (fieldIndexDateReported == -1) {
      return Future.error(StateError('`Date_reported` not found'));
    }
    final fieldIndexCountryCode = headers.indexOf('Country_code');
    if (fieldIndexCountryCode == -1) {
      return Future.error(StateError('`Country_code` not found'));
    }
    final fieldIndexCountry = headers.indexOf('Country');
    if (fieldIndexCountry == -1) {
      return Future.error(StateError('`Country` not found'));
    }
    final fieldIndexCases = headers.indexOf('Cumulative_cases');
    if (fieldIndexCases == -1) {
      return Future.error(StateError('`Cumulative_cases` not found'));
    }
    final fieldIndexDeaths = headers.indexOf('Cumulative_deaths');
    if (fieldIndexDeaths == -1) {
      return Future.error(StateError('`Cumulative_deaths` not found'));
    }

    var i = 1;
    final list = List<WhoCountry>();
    final map = Map<String, int>();
    while (i < data.length) {
      final countryCode = data[i][fieldIndexCountryCode];
      if (!map.containsKey(countryCode)) {
        list.add(WhoCountry(
          countryCode,
          name: data[i][fieldIndexCountry],
        ));
        map[countryCode] = list.length - 1;
      }

      final dateReported = DateTime.tryParse(data[i][fieldIndexDateReported]);
      if (dateReported == null) {
        continue;
      }

      list[map[countryCode]].add(WhoRecord(
        dateReported,
        cases: int.tryParse(data[i][fieldIndexCases]) ?? 0,
        deaths: int.tryParse(data[i][fieldIndexDeaths]) ?? 0,
      ));

      i++;
    }

    return list;
  }
}

@immutable
class WhoCountry {
  final String code;
  final String name;
  final List<WhoRecord> records = [];

  WhoCountry(this.code, {this.name});

  WhoRecord get latest => records.isNotEmpty ? records.last : null;

  void add(WhoRecord record) {
    if (records.isNotEmpty) {
      final last = records.last;
      if (last.cases == record.cases && last.deaths == record.deaths) return;
    }

    records.add(record);
  }

  @override
  String toString() => '$code(${records.map((d) => d.toString()).join(', ')})';
}

@immutable
class WhoRecord {
  final DateTime dateReported;
  final int cases;
  final int deaths;

  WhoRecord(this.dateReported, {this.cases, this.deaths});

  @override
  String toString() =>
      '${dateReported.year}-${dateReported.month}-${dateReported.day}/$cases/$deaths';
}
