import 'package:charts_flutter/flutter.dart' as charts;
import 'package:covid19/api/api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DataTableWidget extends StatefulWidget {
  @override
  _DataTableState createState() => _DataTableState();
}

class _DataTableState extends State<DataTableWidget> {
  _SortOrder order = _SortOrder.deathsDesc;

  _SortOrder _sortedOrder;
  List<ApiCountry> _sortedList;

  @override
  Widget build(BuildContext _) => Consumer<Api>(
        builder: (context, api, __) => api.isLoading
            ? Center(child: CircularProgressIndicator(value: api.progress))
            : api.hasData
                ? SafeArea(child: _buildTable(context, api))
                : Text(api.error.toString()),
      );

  Widget _buildTable(BuildContext context, Api api) {
    final width = MediaQuery.of(context).size.width;
    final showNew = width > 600;

    if (_sortedOrder != order) {
      _sortedList = [...api.countries];
      _sortedList.sort((a, b) {
        switch (order) {
          case _SortOrder.casesAsc:
            return a.latest.casesTotal.compareTo(b.latest.casesTotal);
          case _SortOrder.casesDesc:
            return b.latest.casesTotal.compareTo(a.latest.casesTotal);
          case _SortOrder.deathsAsc:
            return a.latest.deathsTotal.compareTo(b.latest.deathsTotal);
          case _SortOrder.deathsDesc:
            return b.latest.deathsTotal.compareTo(a.latest.deathsTotal);
        }

        return 0;
      });
      _sortedOrder = order;
    }

    return Column(children: [
      Row(children: [
        const Expanded(child: SizedBox.shrink()),
        _Header(
          (order == _SortOrder.deathsAsc
                  ? '↑ '
                  : order == _SortOrder.deathsDesc ? '↓ ' : '') +
              'Deaths',
          onTap: () => setState(() => order = order == _SortOrder.deathsDesc
              ? _SortOrder.deathsAsc
              : _SortOrder.deathsDesc),
        ),
        if (showNew) _NumberBox(),
        _Header(
          (order == _SortOrder.casesAsc
                  ? '↑ '
                  : order == _SortOrder.casesDesc ? '↓ ' : '') +
              'Cases',
          onTap: () => setState(() => order = order == _SortOrder.casesDesc
              ? _SortOrder.casesAsc
              : _SortOrder.casesDesc),
        ),
        if (showNew) _NumberBox(),
      ]),
      Expanded(
        child: ListView.builder(
          itemBuilder: (_, index) => _DataRow(
            country: _sortedList[index],
            showNew: showNew,
            worldLatest: api.worldLatest,
          ),
          itemCount: _sortedList.length,
        ),
      ),
    ]);
  }
}

class _DataRow extends StatelessWidget {
  final ApiCountry country;
  final bool showNew;
  final ApiRecord worldLatest;

  const _DataRow({
    Key key,
    this.country,
    this.showNew,
    this.worldLatest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Padding(
            child: Text(country.name),
            padding: const EdgeInsets.all(8),
          ),
        ),
        _NumberWidget(
          color: Colors.red,
          country: country,
          measureFn: (record) => record.deathsTotal,
        ),
        if (showNew)
          _NumberWidget(
            color: Colors.orange,
            country: country,
            data: '+${_formatNumber(country.latest.deathsNew)}',
            measureFn: (record) => record.deathsNew,
          ),
        _NumberWidget(
          color: Colors.green,
          country: country,
          measureFn: (record) => record.casesTotal,
        ),
        if (showNew)
          _NumberWidget(
            color: Colors.lime,
            country: country,
            data: '+${_formatNumber(country.latest.casesNew)}',
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

class _NumberChart extends StatelessWidget {
  final Color color;
  final ApiCountry country;
  final int Function(ApiRecord) measureFn;

  _NumberChart({
    @required this.color,
    @required this.country,
    Key key,
    @required this.measureFn,
  }) : super(key: key);

  @override
  Widget build(BuildContext _) => charts.TimeSeriesChart(
        [
          charts.Series<ApiRecord, DateTime>(
            id: 'id',
            colorFn: (_, __) => charts.ColorUtil.fromDartColor(color),
            data: country.records,
            domainFn: (record, _) => record.date,
            measureFn: (record, _) => measureFn(record),
          ),
        ],
        domainAxis: charts.DateTimeAxisSpec(
          renderSpec: charts.NoneRenderSpec(),
          viewport: charts.DateTimeExtents(
            start: DateTime(2020, 2, 24),
            end: DateTime.now(),
          ),
        ),
        primaryMeasureAxis:
            charts.NumericAxisSpec(renderSpec: charts.NoneRenderSpec()),
      );
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
  final int Function(ApiRecord) measureFn;

  _NumberWidget({
    @required this.color,
    @required this.country,
    String data,
    Key key,
    @required this.measureFn,
  })  : data = data ?? _formatNumber(measureFn(country.latest)),
        super(key: key);

  @override
  Widget build(BuildContext context) => _NumberBox(
        child: Stack(
          children: [
            _NumberText(data, color: color),
            Positioned.fill(
              child: _NumberChart(
                color: color,
                country: country,
                measureFn: measureFn,
              ),
            ),
          ],
        ),
      );
}

enum _SortOrder {
  casesAsc,
  casesDesc,
  deathsAsc,
  deathsDesc,
}

String _formatNumber(int v) => NumberFormat.compact().format(v);
