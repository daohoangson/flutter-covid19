import 'package:covid19/api/who.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Covid19World extends StatefulWidget {
  @override
  _Covid19WorldState createState() => _Covid19WorldState();
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
    final theme = Theme.of(context);

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
          child: _buildNumber(
            (order == _Covid19Order.deathsAsc
                    ? '↑ '
                    : order == _Covid19Order.deathsDesc ? '↓ ' : '') +
                'Deaths',
            style: theme.textTheme.caption,
          ),
          onTap: () => setState(() => order = order == _Covid19Order.deathsDesc
              ? _Covid19Order.deathsAsc
              : _Covid19Order.deathsDesc),
        ),
        if (showNew) _buildNumber(null),
        InkWell(
          child: _buildNumber(
            (order == _Covid19Order.casesAsc
                    ? '↑ '
                    : order == _Covid19Order.casesDesc ? '↓ ' : '') +
                'Cases',
            style: theme.textTheme.caption,
          ),
          onTap: () => setState(() => order = order == _Covid19Order.casesDesc
              ? _Covid19Order.casesAsc
              : _Covid19Order.casesDesc),
        ),
        if (showNew) _buildNumber(null),
      ]),
      Expanded(
        child: ListView.builder(
          itemBuilder: (_, index) => _buildRow(
            theme,
            api,
            _sortedList[index],
            showNew: showNew,
          ),
          itemCount: _sortedList.length,
        ),
      ),
    ]);
  }

  Widget _buildRow(
    ThemeData theme,
    WhoApi api,
    WhoCountry country, {
    bool showNew = false,
  }) =>
      Row(children: [
        Expanded(
          child: Padding(
            child: Column(
              children: [
                Text(country.name),
                _buildBarGraph(
                    country.latest.cumulativeDeaths, api.cumulativeDeaths,
                    color: Colors.red, showNew: showNew),
                if (showNew)
                  _buildBarGraph(
                    country.latest.newDeaths,
                    api.newDeaths,
                    color: Colors.orange,
                  ),
                _buildBarGraph(
                    country.latest.cumulativeCases, api.cumulativeCases,
                    color: Colors.green, showNew: showNew),
                if (showNew)
                  _buildBarGraph(
                    country.latest.newCases,
                    api.newCases,
                    color: Colors.lime,
                  ),
              ],
              crossAxisAlignment: CrossAxisAlignment.stretch,
            ),
            padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
          ),
        ),
        _buildNumber(
          _formatNumber(country.latest.cumulativeDeaths),
          style: theme.textTheme.caption.copyWith(color: Colors.red),
        ),
        if (showNew)
          _buildNumber(
            country.latest.newDeaths > 0
                ? '+${_formatNumber(country.latest.newDeaths)}'
                : null,
            style: theme.textTheme.caption.copyWith(color: Colors.orange),
          ),
        _buildNumber(
          _formatNumber(country.latest.cumulativeCases),
          style: theme.textTheme.caption.copyWith(color: Colors.green),
        ),
        if (showNew)
          _buildNumber(
            country.latest.newCases > 0
                ? '+${_formatNumber(country.latest.newCases)}'
                : null,
            style: theme.textTheme.caption.copyWith(color: Colors.lime),
          ),
      ]);

  Widget _buildBarGraph(int country, int world,
          {Color color, bool showNew = true}) =>
      world > 0
          ? FractionallySizedBox(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(color: color),
                height: showNew ? 2 : 4,
              ),
              widthFactor: country / world,
            )
          : const SizedBox.shrink();

  Widget _buildNumber(String data, {TextStyle style}) => SizedBox(
        child: data != null
            ? Padding(
                child: Text(
                  data,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
                padding: const EdgeInsets.all(8),
              )
            : null,
        width: 75,
      );

  String _formatNumber(int v) => NumberFormat.compact().format(v);
}

enum _Covid19Order {
  casesAsc,
  casesDesc,
  deathsAsc,
  deathsDesc,
}
