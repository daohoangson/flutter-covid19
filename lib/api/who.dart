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

    _cumulativeCases = 0;
    _newCases = 0;
    _cumulativeDeaths = 0;
    _newDeaths = 0;
    for (final country in v) {
      _cumulativeCases += country.latest.cumulativeCases;
      _newCases += country.latest.newCases;
      _cumulativeDeaths += country.latest.cumulativeDeaths;
      _newDeaths += country.latest.newDeaths;
    }

    notifyListeners();
  }

  int _cumulativeCases = 0;
  int get cumulativeCases => _cumulativeCases;

  int _newCases = 0;
  int get newCases => _newCases;

  int _cumulativeDeaths = 0;
  int get cumulativeDeaths => _cumulativeDeaths;

  int _newDeaths = 0;
  int get newDeaths => _newDeaths;

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
    final fieldIndexNewCases = headers.indexOf('New_cases');
    if (fieldIndexNewCases == -1) {
      return Future.error(StateError('`New_cases` not found'));
    }
    final fieldIndexCumulativeCases = headers.indexOf('Cumulative_cases');
    if (fieldIndexCumulativeCases == -1) {
      return Future.error(StateError('`Cumulative_cases` not found'));
    }
    final fieldIndexNewDeaths = headers.indexOf('New_deaths');
    if (fieldIndexNewDeaths == -1) {
      return Future.error(StateError('`New_deaths` not found'));
    }
    final fieldIndexCumulativeDeaths = headers.indexOf('Cumulative_deaths');
    if (fieldIndexCumulativeDeaths == -1) {
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

      list[map[countryCode]].records.add(WhoRecord(
            dateReported,
            newCases: int.tryParse(data[i][fieldIndexNewCases]) ?? 0,
            cumulativeCases:
                int.tryParse(data[i][fieldIndexCumulativeCases]) ?? 0,
            newDeaths: int.tryParse(data[i][fieldIndexNewDeaths]) ?? 0,
            cumulativeDeaths:
                int.tryParse(data[i][fieldIndexCumulativeDeaths]) ?? 0,
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

  @override
  String toString() => '$code(${records.map((d) => d.toString()).join(', ')})';
}

@immutable
class WhoRecord {
  final DateTime dateReported;
  final int newCases;
  final int cumulativeCases;
  final int newDeaths;
  final int cumulativeDeaths;

  WhoRecord(
    this.dateReported, {
    this.newCases,
    this.cumulativeCases,
    this.newDeaths,
    this.cumulativeDeaths,
  });

  @override
  String toString() =>
      '${dateReported.year}-${dateReported.month}-${dateReported.day}/'
      '$cumulativeCases/$cumulativeDeaths';
}
