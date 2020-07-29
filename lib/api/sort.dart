import 'package:covid19/api/api.dart';

class SortOrder {
  final int Function(ApiRecord, ApiRecord) _compare1;
  final int Function(ApiRecord, ApiRecord) _compare2;
  final int Function(ApiRecord) measure;

  const SortOrder(
    this._compare1,
    this._compare2,
    this.measure,
  );

  List<ApiCountry> sort(Iterable<ApiCountry> list) => [...list]..sort(_compare);

  int _compare(ApiCountry a, ApiCountry b) {
    final aa = a.latest;
    final bb = b.latest;

    var cmp = _compare1(aa, bb);
    if (cmp == 0) {
      cmp = _compare2(aa, bb);
    }

    return cmp;
  }
}

const casesTotalAsc = SortOrder(
  _casesTotalAsc,
  _deathsTotalAsc,
  _casesTotal,
);

const casesTotalDesc = SortOrder(
  _casesTotalDesc,
  _deathsTotalDesc,
  _casesTotal,
);

const deathsTotalAsc = SortOrder(
  _deathsTotalAsc,
  _casesTotalAsc,
  _deathsTotal,
);

const deathsTotalDesc = SortOrder(
  _deathsTotalDesc,
  _casesTotalDesc,
  _deathsTotal,
);

int _casesTotal(ApiRecord r) => r.casesTotal;

int _deathsTotal(ApiRecord r) => r.deathsTotal;

int _casesTotalAsc(ApiRecord a, ApiRecord b) =>
    a.casesTotal.compareTo(b.casesTotal);

int _casesTotalDesc(ApiRecord a, ApiRecord b) =>
    b.casesTotal.compareTo(a.casesTotal);

int _deathsTotalAsc(ApiRecord a, ApiRecord b) =>
    a.deathsTotal.compareTo(b.deathsTotal);

int _deathsTotalDesc(ApiRecord a, ApiRecord b) =>
    b.deathsTotal.compareTo(a.deathsTotal);
