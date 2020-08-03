import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

abstract class Api extends ChangeNotifier {
  List<ApiCountry> _countries;
  List<ApiCountry> get countries => _countries;
  ApiRecord _worldLatest;
  ApiRecord get worldLatest => _worldLatest;
  void setData({
    List<ApiCountry> countries,
    ApiRecord worldLatest,
  }) {
    _countries = countries;
    _worldLatest = worldLatest;
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

  double _progress = 0;
  double get progress => _progress;
  set progress(double v) {
    assert(_isLoading);
    assert(0 <= v);
    assert(v <= 1.0);
    _progress = v;
    notifyListeners();
  }
}

@immutable
class ApiCountry {
  final String code;
  final String name;
  final List<ApiRecord> records = [];

  ApiCountry(this.code, {this.name});

  ApiRecord get latest => records.isNotEmpty ? records.last : null;

  @override
  String toString() => '$code(${records.map((r) => '$r').join(', ')})';
}

@immutable
class ApiRecord {
  final int casesNew;
  final int casesTotal;
  final DateTime date;
  final int deathsNew;
  final int deathsTotal;

  ApiRecord({
    this.casesNew,
    this.casesTotal,
    this.date,
    this.deathsNew,
    this.deathsTotal,
  });

  @override
  String toString() => '${DateFormat.yMd().format(date)}('
      'cases=$casesTotal,'
      'deaths=$deathsTotal'
      ')';

  factory ApiRecord.from(Iterable<ApiRecord> records) {
    DateTime date;
    var casesNew = 0;
    var casesTotal = 0;
    var deathsNew = 0;
    var deathsTotal = 0;
    for (final record in records) {
      date ??= record.date;
      casesNew += record.casesNew;
      casesTotal += record.casesTotal;
      deathsNew += record.deathsNew;
      deathsTotal += record.deathsTotal;
    }
    return ApiRecord(
      casesNew: casesNew,
      casesTotal: casesTotal,
      date: date,
      deathsNew: deathsNew,
      deathsTotal: deathsTotal,
    );
  }
}
