import 'package:covid19/api/api.dart';
import 'package:flutter/material.dart';

class SortOrder {
  final _TypeAscDesc _typeAscDesc;
  final _TypeCasesDeaths _typeCasesDeaths;
  final _TypeNewTotal _typeNewTotal;
  final int Function(ApiRecord) measure;
  final int Function(ApiRecord) _measure2;
  final List<int> seriousnessValues;

  const SortOrder._(
    this._typeAscDesc,
    this._typeCasesDeaths,
    this._typeNewTotal,
    this.measure,
    this._measure2,
    this.seriousnessValues,
  );

  bool get isAsc => _typeAscDesc == _TypeAscDesc.asc;

  bool get isCases => _typeCasesDeaths == _TypeCasesDeaths.cases;

  bool get isNew => _typeNewTotal == _TypeNewTotal.new_;

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

  SortOrder flipNewTotal() {
    for (final pair in _pairs) {
      final other = isAsc ? pair.asc : pair.desc;
      if (other._typeCasesDeaths == _typeCasesDeaths &&
          other._typeNewTotal != _typeNewTotal) {
        return other;
      }
    }

    return this;
  }

  int _compare(ApiCountry a, ApiCountry b) {
    final aa = a.latest;
    final bb = b.latest;

    final a1 = measure(aa);
    final b1 = measure(bb);
    final cmp1 = isAsc ? a1.compareTo(b1) : b1.compareTo(a1);
    if (cmp1 != 0) return cmp1;

    final a2 = _measure2(aa);
    final b2 = _measure2(bb);
    return isAsc ? a2.compareTo(b2) : b2.compareTo(a2);
  }
}

class SortOrderPair {
  final SortOrder asc;
  final SortOrder desc;

  const SortOrderPair._(this.asc, this.desc);

  String get header =>
      asc.isNew ? (asc.isCases ? 'New' : 'Today') : headerCasesDeaths;

  String get headerCasesDeaths => asc.isCases ? 'Cases' : 'Deaths';

  SortOrder flipAscDesc(SortOrder order) => order == desc ? asc : desc;
}

enum _TypeAscDesc {
  asc,
  desc,
}

enum _TypeCasesDeaths {
  cases,
  deaths,
}

enum _TypeNewTotal {
  new_,
  total,
}

const casesNew = SortOrderPair._(
  SortOrder._(
    _TypeAscDesc.asc,
    _TypeCasesDeaths.cases,
    _TypeNewTotal.new_,
    _casesNew,
    _deathsNew,
    _seriousnessCasesNew,
  ),
  SortOrder._(
    _TypeAscDesc.desc,
    _TypeCasesDeaths.cases,
    _TypeNewTotal.new_,
    _casesNew,
    _deathsNew,
    _seriousnessCasesNew,
  ),
);

const casesTotal = SortOrderPair._(
  SortOrder._(
    _TypeAscDesc.asc,
    _TypeCasesDeaths.cases,
    _TypeNewTotal.total,
    _casesTotal,
    _deathsTotal,
    _seriousnessCasesTotal,
  ),
  SortOrder._(
    _TypeAscDesc.desc,
    _TypeCasesDeaths.cases,
    _TypeNewTotal.total,
    _casesTotal,
    _deathsTotal,
    _seriousnessCasesTotal,
  ),
);

const deathsNew = SortOrderPair._(
  SortOrder._(
    _TypeAscDesc.asc,
    _TypeCasesDeaths.deaths,
    _TypeNewTotal.new_,
    _deathsNew,
    _casesNew,
    _seriousnessDeathsNew,
  ),
  SortOrder._(
    _TypeAscDesc.desc,
    _TypeCasesDeaths.deaths,
    _TypeNewTotal.new_,
    _deathsNew,
    _casesNew,
    _seriousnessDeathsNew,
  ),
);

const deathsTotal = SortOrderPair._(
  SortOrder._(
    _TypeAscDesc.asc,
    _TypeCasesDeaths.deaths,
    _TypeNewTotal.total,
    _deathsTotal,
    _casesTotal,
    _seriousnessDeathsTotal,
  ),
  SortOrder._(
    _TypeAscDesc.desc,
    _TypeCasesDeaths.deaths,
    _TypeNewTotal.total,
    _deathsTotal,
    _casesTotal,
    _seriousnessDeathsTotal,
  ),
);

const _pairs = [
  casesTotal,
  casesNew,
  deathsTotal,
  deathsNew,
];

int _casesNew(ApiRecord r) => r.casesNew;

int _casesTotal(ApiRecord r) => r.casesTotal;

int _deathsNew(ApiRecord r) => r.deathsNew;

int _deathsTotal(ApiRecord r) => r.deathsTotal;

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
