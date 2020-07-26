import 'package:charts_flutter/flutter.dart' as charts;
import 'package:covid19/api/who.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Covid19World extends StatefulWidget {
  @override
  _Covid19WorldState createState() => _Covid19WorldState();

  static Widget _buildNumber({
    Color color,
    BuildContext context,
    WhoCountry country,
    String data,
    int Function(WhoRecord) measureFn,
  }) {
    if (country != null && measureFn != null)
      data ??= _formatNumber(measureFn(country.latest));

    return SizedBox(
      child: data != null
          ? Stack(
              children: [
                Padding(
                  child: Text(
                    data,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context != null
                        ? Theme.of(context)
                            .textTheme
                            .caption
                            .copyWith(color: color)
                        : null,
                  ),
                  padding: const EdgeInsets.all(8),
                ),
                if (color != null && country != null && measureFn != null)
                  Positioned.fill(
                    child: charts.TimeSeriesChart(
                      [
                        charts.Series<WhoRecord, DateTime>(
                          id: 'id',
                          colorFn: (_, __) =>
                              charts.ColorUtil.fromDartColor(color),
                          data: country.records,
                          domainFn: (datum, _) => datum.dateReported,
                          measureFn: (datum, _) => measureFn(datum),
                        ),
                      ],
                      domainAxis: charts.DateTimeAxisSpec(
                        renderSpec: charts.NoneRenderSpec(),
                        viewport: charts.DateTimeExtents(
                          start: DateTime(2020, 2, 24),
                          end: DateTime.now(),
                        ),
                      ),
                      primaryMeasureAxis: charts.NumericAxisSpec(
                          renderSpec: charts.NoneRenderSpec()),
                    ),
                  ),
              ],
              overflow: Overflow.clip,
            )
          : null,
      width: 75,
    );
  }

  static String _formatNumber(int v) => NumberFormat.compact().format(v);
}

class _Covid19WorldState extends State<Covid19World> {
  _Covid19Order order = _Covid19Order.deathsDesc;

  _Covid19Order _sortedOrder;
  List<WhoCountry> _sortedList;

  @override
  Widget build(BuildContext _) => Consumer<WhoApi>(
        builder: (context, api, __) => api.isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : api.hasData
                ? SafeArea(child: _buildTable(context, api))
                : Text(api.error.toString()),
      );

  Widget _buildTable(BuildContext context, WhoApi api) {
    final width = MediaQuery.of(context).size.width;
    final showNew = width > 600;

    if (_sortedOrder != order) {
      _sortedList = [...api.countries];
      _sortedList.sort((a, b) {
        switch (order) {
          case _Covid19Order.casesAsc:
            return a.latest.cumulativeCases.compareTo(b.latest.cumulativeCases);
          case _Covid19Order.casesDesc:
            return b.latest.cumulativeCases.compareTo(a.latest.cumulativeCases);
          case _Covid19Order.deathsAsc:
            return a.latest.cumulativeDeaths
                .compareTo(b.latest.cumulativeDeaths);
          case _Covid19Order.deathsDesc:
            return b.latest.cumulativeDeaths
                .compareTo(a.latest.cumulativeDeaths);
        }

        return 0;
      });
      _sortedOrder = order;
    }

    return Column(children: [
      Row(children: [
        const Expanded(child: SizedBox.shrink()),
        InkWell(
          child: Covid19World._buildNumber(
            context: context,
            data: (order == _Covid19Order.deathsAsc
                    ? '↑ '
                    : order == _Covid19Order.deathsDesc ? '↓ ' : '') +
                'Deaths',
          ),
          onTap: () => setState(() => order = order == _Covid19Order.deathsDesc
              ? _Covid19Order.deathsAsc
              : _Covid19Order.deathsDesc),
        ),
        if (showNew) Covid19World._buildNumber(),
        InkWell(
          child: Covid19World._buildNumber(
            context: context,
            data: (order == _Covid19Order.casesAsc
                    ? '↑ '
                    : order == _Covid19Order.casesDesc ? '↓ ' : '') +
                'Cases',
          ),
          onTap: () => setState(() => order = order == _Covid19Order.casesDesc
              ? _Covid19Order.casesAsc
              : _Covid19Order.casesDesc),
        ),
        if (showNew) Covid19World._buildNumber(),
      ]),
      Expanded(
        child: ListView.builder(
          itemBuilder: (_, index) {
            final country = _sortedList[index];
            return _Covid19Row(
              country: country,
              showNew: showNew,
              world: api.worldLatest,
            );
          },
          itemCount: _sortedList.length,
        ),
      ),
    ]);
  }
}

enum _Covid19Order {
  casesAsc,
  casesDesc,
  deathsAsc,
  deathsDesc,
}

class _Covid19Row extends StatelessWidget {
  final WhoCountry country;
  final bool showNew;
  final WhoRecord world;

  const _Covid19Row({
    Key key,
    this.country,
    this.showNew,
    this.world,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Padding(
            child: Column(
              children: [
                Text(country.name),
                _buildBarGraph(
                  country.latest.cumulativeDeaths,
                  world.cumulativeDeaths,
                  color: Colors.red,
                  showNew: showNew,
                ),
                if (showNew)
                  _buildBarGraph(
                    country.latest.newDeaths,
                    world.newDeaths,
                    color: Colors.orange,
                  ),
                _buildBarGraph(
                  country.latest.cumulativeCases,
                  world.cumulativeCases,
                  color: Colors.green,
                  showNew: showNew,
                ),
                if (showNew)
                  _buildBarGraph(
                    country.latest.newCases,
                    world.newCases,
                    color: Colors.lime,
                  ),
              ],
              crossAxisAlignment: CrossAxisAlignment.stretch,
            ),
            padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
          ),
        ),
        Covid19World._buildNumber(
          color: Colors.red,
          context: context,
          country: country,
          measureFn: (record) => record.cumulativeDeaths,
        ),
        if (showNew)
          Covid19World._buildNumber(
            color: Colors.orange,
            context: context,
            country: country,
            data: '+${Covid19World._formatNumber(country.latest.newDeaths)}',
            measureFn: (record) => record.newDeaths,
          ),
        Covid19World._buildNumber(
          color: Colors.green,
          context: context,
          country: country,
          measureFn: (record) => record.cumulativeCases,
        ),
        if (showNew)
          Covid19World._buildNumber(
            color: Colors.lime,
            context: context,
            country: country,
            data: '+${Covid19World._formatNumber(country.latest.newCases)}',
            measureFn: (record) => record.newCases,
          ),
      ]);

  Widget _buildBarGraph(int value, int worldValue,
          {Color color, bool showNew = true}) =>
      worldValue > 0
          ? FractionallySizedBox(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(color: color),
                height: showNew ? 2 : 4,
              ),
              widthFactor: value / worldValue,
            )
          : const SizedBox.shrink();
}
