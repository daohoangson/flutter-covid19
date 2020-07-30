import 'package:covid19/api/api.dart';
import 'package:covid19/api/sort.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

enum Highlighter {
  map,
  search,
  table,
}
