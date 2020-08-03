import 'package:covid19/data/api.dart';
import 'package:covid19/data/ipdata/ipdata.dart';
import 'package:covid19/data/sort.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  ApiCountry _highlight;
  ApiCountry get highlight => _highlight;
  Highlighter _highlighter;
  Highlighter get highlighter => _highlighter;
  void setHighlight(Highlighter highlighter, ApiCountry country) {
    if (country == _highlight) return;
    _highlight = country;
    _highlighter = highlighter;
    notifyListeners();
  }

  Ipdata _ipdata;
  Ipdata get ipdata {
    if (_ipdata == null) {
      _ipdata = Ipdata();
      _ipdata.addListener(notifyListeners);
    }
    return _ipdata;
  }

  static const kOrderPrefKey = 'app_state.order';
  SortOrder _order = deathsTotal.desc;
  SortOrder get order => _order;
  set order(SortOrder v) {
    if (v == _order) return;
    _order = v;

    SharedPreferences.getInstance()
        .then((p) => p.setString(kOrderPrefKey, v.toString()))
        .then((_) => notifyListeners());
  }

  static const kShowPerformanceOverlayPrefKey =
      'app_state.showPerformanceOverlay';
  bool _showPerformanceOverlay = false;
  bool get showPerformanceOverlay => _showPerformanceOverlay;
  set showPerformanceOverlay(bool v) {
    if (v == _showPerformanceOverlay) return;
    _showPerformanceOverlay = v;

    SharedPreferences.getInstance()
        .then((p) => p.setBool(kShowPerformanceOverlayPrefKey, v))
        .then((_) => notifyListeners());
  }

  static const kUseHqMapPrefKey = 'app_state.useHqMap';
  bool _useHqMap = true;
  bool get useHqMap => _useHqMap;
  set useHqMap(bool v) {
    if (v == _useHqMap) return;
    _useHqMap = v;

    SharedPreferences.getInstance()
        .then((p) => p.setBool(kUseHqMapPrefKey, v))
        .then((_) => notifyListeners());
  }

  Future<void> loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    final orderStr = p.getString(kOrderPrefKey);
    if (orderStr != null) {
      final orderParsed = SortOrder.fromString(orderStr);
      if (orderParsed != null) order = orderParsed;
    }

    final showPerformanceOverlayOrNull =
        p.getBool(kShowPerformanceOverlayPrefKey);
    if (showPerformanceOverlayOrNull != null) {
      showPerformanceOverlay = showPerformanceOverlayOrNull;
    }

    final useHqMapOrNull = p.getBool(kUseHqMapPrefKey);
    if (useHqMapOrNull != null) {
      useHqMap = useHqMapOrNull;
    }
  }

  static AppState of(BuildContext context) =>
      Provider.of<AppState>(context, listen: false);
}

enum Highlighter {
  map,
  search,
  table,
}
