import 'package:covid19/api/sort.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppState extends ChangeNotifier {
  String _highlightCountryCode;
  String get highlightCountryCode => _highlightCountryCode;
  set highlightCountryCode(String v) {
    if (v == _highlightCountryCode) return;
    _highlightCountryCode = v;
    notifyListeners();
  }

  SortOrder __order = deathsTotalDesc;
  SortOrder get order => __order;
  set order(SortOrder v) {
    if (v == __order) return;
    __order = v;
    notifyListeners();
  }

  static AppState of(BuildContext context) =>
      Provider.of<AppState>(context, listen: false);
}
