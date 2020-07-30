import 'package:covid19/api/api.dart';
import 'package:flutter/material.dart';

class SortOrder {
  final int Function(ApiRecord, ApiRecord) _compare1;
  final int Function(ApiRecord, ApiRecord) _compare2;
  final int Function(ApiRecord) measure;
  final List<int> seriousnessValues;

  const SortOrder._(
    this._compare1,
    this._compare2,
    this.measure,
    this.seriousnessValues,
  );

  int calculateSeriousness(ApiRecord record) {
    final value = measure(record);
    final max = seriousnessValues.length;
    for (var i = max - 1; i >= 0; i--) {
      if (value > seriousnessValues[i]) {
        return i + 1;
      }
    }

    return 0;
  }

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

class SortOrderPair {
  final SortOrder asc;
  final SortOrder desc;
  final String header;

  const SortOrderPair._(this.header, this.asc, this.desc);

  SortOrder flip(SortOrder order) => order == desc ? asc : desc;
}

const casesNew = SortOrderPair._(
  'New',
  SortOrder._(
    _casesNewAsc,
    _deathsNewAsc,
    _casesNew,
    _seriousnessCasesNew,
  ),
  SortOrder._(
    _casesNewDesc,
    _deathsNewDesc,
    _casesNew,
    _seriousnessCasesNew,
  ),
);

const casesTotal = SortOrderPair._(
  'Cases',
  SortOrder._(
    _casesTotalAsc,
    _deathsTotalAsc,
    _casesTotal,
    _seriousnessCasesTotal,
  ),
  SortOrder._(
    _casesTotalDesc,
    _deathsTotalDesc,
    _casesTotal,
    _seriousnessCasesTotal,
  ),
);

const deathsNew = SortOrderPair._(
  'Today',
  SortOrder._(
    _deathsNewAsc,
    _casesNewAsc,
    _deathsNew,
    _seriousnessDeathsNew,
  ),
  SortOrder._(
    _deathsNewDesc,
    _casesNewDesc,
    _deathsNew,
    _seriousnessDeathsNew,
  ),
);

const deathsTotal = SortOrderPair._(
  'Deaths',
  SortOrder._(
    _deathsTotalAsc,
    _casesTotalAsc,
    _deathsTotal,
    _seriousnessDeathsTotal,
  ),
  SortOrder._(
    _deathsTotalDesc,
    _casesTotalDesc,
    _deathsTotal,
    _seriousnessDeathsTotal,
  ),
);

int _casesNew(ApiRecord r) => r.casesNew;

int _casesTotal(ApiRecord r) => r.casesTotal;

int _deathsNew(ApiRecord r) => r.deathsNew;

int _deathsTotal(ApiRecord r) => r.deathsTotal;

int _casesNewAsc(ApiRecord a, ApiRecord b) => a.casesNew.compareTo(b.casesNew);

int _casesNewDesc(ApiRecord a, ApiRecord b) => b.casesNew.compareTo(a.casesNew);

int _casesTotalAsc(ApiRecord a, ApiRecord b) =>
    a.casesTotal.compareTo(b.casesTotal);

int _casesTotalDesc(ApiRecord a, ApiRecord b) =>
    b.casesTotal.compareTo(a.casesTotal);

int _deathsNewAsc(ApiRecord a, ApiRecord b) =>
    a.deathsNew.compareTo(b.deathsNew);

int _deathsNewDesc(ApiRecord a, ApiRecord b) =>
    b.deathsNew.compareTo(a.deathsNew);

int _deathsTotalAsc(ApiRecord a, ApiRecord b) =>
    a.deathsTotal.compareTo(b.deathsTotal);

int _deathsTotalDesc(ApiRecord a, ApiRecord b) =>
    b.deathsTotal.compareTo(a.deathsTotal);

const _seriousnessCasesNew = <int>[
  -1,
  0,
  10,
  50,
  200,
  1000,
  5000,
  20000,
  50000,
  100000,
];

const _seriousnessCasesTotal = <int>[
  -1,
  10,
  100,
  1000,
  10000,
  50000,
  200000,
  1000000,
  2000000,
  5000000,
];

const _seriousnessDeathsNew = <int>[
  -1,
  0,
  2,
  5,
  10,
  20,
  100,
  500,
  1000,
  2000,
];

const _seriousnessDeathsTotal = <int>[
  -1,
  0,
  10,
  100,
  500,
  2000,
  10000,
  50000,
  100000,
  200000,
];

final kColors = <Color>[
  Colors.grey,
  Colors.green[700],
  Colors.green,
  Colors.lime[600],
  Colors.yellow[700],
  Colors.orange,
  Colors.orange[800],
  Colors.red[600],
  Colors.red[900],
  Colors.purple[800],
  Colors.black87,
];
