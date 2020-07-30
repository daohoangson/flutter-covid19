import 'package:covid19/api/api.dart';
import 'package:covid19/api/sort.dart';
import 'package:covid19/app_state.dart';
import 'package:covid19/widget/graph.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TableWidget extends StatefulWidget {
  @override
  _TableState createState() => _TableState();
}

class _TableState extends State<TableWidget> {
  SortOrder _sortedOrder;
  List<ApiCountry> _sortedList;

  @override
  Widget build(BuildContext _) => Consumer2<Api, AppState>(
        builder: (_, api, app, __) => api.hasData
            ? SafeArea(
                child: LayoutBuilder(
                builder: (_, bc) =>
                    _buildTable(api, app, showNew: bc.maxWidth > 600),
              ))
            : Text(api.error?.toString() ??
                'API data is unavailable. Please try again later'),
      );

  Widget _buildTable(Api api, AppState app, {bool showNew}) {
    final order = app.order;
    if (_sortedOrder != order) {
      _sortedList = order.sort(api.countries);
      _sortedOrder = order;
    }

    return Column(children: [
      Row(children: [
        const Expanded(child: SizedBox.shrink()),
        _buildHeader(
          (order == deathsTotalAsc
                  ? '↑ '
                  : order == deathsTotalDesc ? '↓ ' : '') +
              'Deaths',
          onTap: () => setState(() => AppState.of(context).order =
              order == deathsTotalDesc ? deathsTotalAsc : deathsTotalDesc),
        ),
        if (showNew) _NumberBox(),
        _buildHeader(
          (order == casesTotalAsc
                  ? '↑ '
                  : order == casesTotalDesc ? '↓ ' : '') +
              'Cases',
          onTap: () => setState(() => AppState.of(context).order =
              order == casesTotalDesc ? casesTotalAsc : casesTotalDesc),
        ),
        if (showNew) _NumberBox(),
      ]),
      Expanded(
        child: _ListView(
          countries: _sortedList,
          highlight: app.highlight,
          highlighter: app.highlighter,
          showNew: showNew,
        ),
      ),
    ]);
  }

  Widget _buildHeader(String data, {VoidCallback onTap}) => InkWell(
        child: _NumberBox(child: _NumberText(data)),
        onTap: onTap,
      );
}

class _ListView extends StatefulWidget {
  final List<ApiCountry> countries;
  final ApiCountry highlight;
  final Highlighter highlighter;
  final bool showNew;

  const _ListView({
    @required this.countries,
    this.highlight,
    this.highlighter,
    Key key,
    @required this.showNew,
  }) : super(key: key);

  @override
  _ListState createState() => _ListState();
}

class _ListState extends State<_ListView> {
  final _controller = ItemScrollController();

  @override
  Widget build(BuildContext context) => ScrollablePositionedList.builder(
        itemBuilder: (_, index) => _buildCountry(
          country: widget.countries[index],
          number: index + 1,
        ),
        itemCount: widget.countries.length,
        itemScrollController: _controller,
      );

  @override
  void didUpdateWidget(_ListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final needsScrolling = false ||
        // 1. Someone else (not us) changed the highlight country
        (widget.highlight != oldWidget.highlight &&
            widget.highlighter != Highlighter.table) ||
        // 2. Sort order has been changed
        (widget.countries != oldWidget.countries);

    if (needsScrolling) {
      // let's scroll to make sure the highlighed is visible
      final index = widget.highlight != null
          ? widget.countries.indexOf(widget.highlight)
          : 0;
      _controller.scrollTo(
        index: index.clamp(0, widget.countries.length - 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      );
    }
  }

  Widget _buildCountry({ApiCountry country, int number}) => InkWell(
        child: Row(
          children: [
            Expanded(child: _buildName(number, country)),
            _buildNumber(
              color: Colors.red,
              country: country,
              graphMode: GraphMode.line,
              measureFn: (record) => record.deathsTotal,
            ),
            if (widget.showNew)
              _buildNumber(
                color: Colors.orange,
                country: country,
                data: '+${_formatNumber(country.latest.deathsNew)}',
                graphMode: GraphMode.bar,
                measureFn: (record) => record.deathsNew,
              ),
            _buildNumber(
              color: Colors.green,
              country: country,
              graphMode: GraphMode.line,
              measureFn: (record) => record.casesTotal,
            ),
            if (widget.showNew)
              _buildNumber(
                color: Colors.lime,
                country: country,
                data: '+${_formatNumber(country.latest.casesNew)}',
                graphMode: GraphMode.bar,
                measureFn: (record) => record.casesNew,
              ),
          ],
        ),
        onTap: () =>
            AppState.of(context).setHighlight(Highlighter.table, country),
      );

  Widget _buildName(int number, ApiCountry country) => Padding(
        child: Text(
          '$number. ${country.name}',
          style: country == widget.highlight
              ? TextStyle(fontWeight: FontWeight.bold)
              : null,
        ),
        padding: const EdgeInsets.all(8),
      );

  Widget _buildNumber({
    Color color,
    ApiCountry country,
    String data,
    GraphMode graphMode,
    int Function(ApiRecord) measureFn,
  }) =>
      _NumberBox(
        child: Padding(
          child: Stack(
            children: [
              _NumberText(
                data ?? _formatNumber(measureFn(country.latest)),
                color: color,
              ),
              Positioned.fill(
                child: GraphWidget(
                  color: color,
                  id: "${country.code}-${measureFn(country.latest)}",
                  measureFn: measureFn,
                  mode: graphMode,
                  records: country.records,
                ),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
      );
}

class _NumberBox extends StatelessWidget {
  final Widget child;

  const _NumberBox({this.child, Key key}) : super(key: key);

  @override
  Widget build(BuildContext _) => SizedBox(child: child, width: 75);
}

class _NumberText extends StatelessWidget {
  final Color color;
  final String data;

  const _NumberText(
    this.data, {
    this.color,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
        child: Text(
          data,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.caption.copyWith(color: color),
        ),
        padding: const EdgeInsets.all(8),
      );
}

String _formatNumber(int v) => NumberFormat.compact().format(v);
