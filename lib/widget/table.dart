import 'package:covid19/api/api.dart';
import 'package:covid19/api/sort.dart';
import 'package:covid19/app_state.dart';
import 'package:covid19/widget/graph.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TableWidget extends StatefulWidget {
  @override
  _TableState createState() => _TableState();
}

class _TableState extends State<TableWidget> {
  SortOrder _sortedOrder;
  List<ApiCountry> _sortedList;

  @override
  Widget build(BuildContext _) => Consumer2<Api, AppState>(
        builder: (_, api, data, __) => api.hasData
            ? SafeArea(
                child: LayoutBuilder(
                builder: (_, bc) =>
                    _buildTable(api, data.order, showNew: bc.maxWidth > 600),
              ))
            : Text(api.error?.toString() ??
                'API data is unavailable. Please try again later'),
      );

  Widget _buildTable(Api api, SortOrder order, {bool showNew}) {
    if (_sortedOrder != order) {
      _sortedList = order.sort(api.countries);
      _sortedOrder = order;
    }

    return Column(children: [
      Row(children: [
        const Expanded(child: SizedBox.shrink()),
        _Header(
          (order == deathsTotalAsc
                  ? '↑ '
                  : order == deathsTotalDesc ? '↓ ' : '') +
              'Deaths',
          onTap: () => setState(() => AppState.of(context).order =
              order == deathsTotalDesc ? deathsTotalAsc : deathsTotalDesc),
        ),
        if (showNew) _NumberBox(),
        _Header(
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
        child: ListView.builder(
          itemBuilder: (_, index) => _DataRow(
            country: _sortedList[index],
            index: index,
            showNew: showNew,
          ),
          itemCount: _sortedList.length,
        ),
      ),
    ]);
  }
}

class _DataRow extends StatelessWidget {
  final ApiCountry country;
  final int index;
  final bool showNew;

  const _DataRow({
    @required this.country,
    @required this.index,
    Key key,
    this.showNew,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: InkWell(
            child: Padding(
              child: Text('${index + 1}. ${country.name}'),
              padding: const EdgeInsets.all(8),
            ),
            onTap: () =>
                AppState.of(context).highlightCountryCode = country.code,
          ),
        ),
        _NumberWidget(
          color: Colors.red,
          country: country,
          graphMode: GraphMode.line,
          measureFn: (record) => record.deathsTotal,
        ),
        if (showNew)
          _NumberWidget(
            color: Colors.orange,
            country: country,
            data: '+${_formatNumber(country.latest.deathsNew)}',
            graphMode: GraphMode.bar,
            measureFn: (record) => record.deathsNew,
          ),
        _NumberWidget(
          color: Colors.green,
          country: country,
          graphMode: GraphMode.line,
          measureFn: (record) => record.casesTotal,
        ),
        if (showNew)
          _NumberWidget(
            color: Colors.lime,
            country: country,
            data: '+${_formatNumber(country.latest.casesNew)}',
            graphMode: GraphMode.bar,
            measureFn: (record) => record.casesNew,
          ),
      ]);
}

class _Header extends StatelessWidget {
  final String data;
  final VoidCallback onTap;

  const _Header(this.data, {Key key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) => InkWell(
        child: _NumberBox(child: _NumberText(data)),
        onTap: onTap,
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

class _NumberWidget extends StatelessWidget {
  final Color color;
  final ApiCountry country;
  final String data;
  final GraphMode graphMode;
  final int Function(ApiRecord) measureFn;

  _NumberWidget({
    @required this.color,
    @required this.country,
    String data,
    Key key,
    @required this.graphMode,
    @required this.measureFn,
  })  : data = data ?? _formatNumber(measureFn(country.latest)),
        super(key: key);

  @override
  Widget build(BuildContext context) => _NumberBox(
        child: Stack(
          children: [
            _NumberText(data, color: color),
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
      );
}

String _formatNumber(int v) => NumberFormat.compact().format(v);
