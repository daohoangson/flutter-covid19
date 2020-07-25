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

    final columnWidths = {0: const FlexColumnWidth()};
    final defaultColumnWidth = const FixedColumnWidth(75);

    return Column(children: [
      Table(
        children: [
          TableRow(children: [
            const SizedBox.shrink(),
            InkWell(
              child: _buildText(
                (order == _Covid19Order.deathsAsc
                        ? '↑ '
                        : order == _Covid19Order.deathsDesc ? '↓ ' : '') +
                    'Deaths',
                style: theme.textTheme.caption,
              ),
              onTap: () => setState(() => order =
                  order == _Covid19Order.deathsDesc
                      ? _Covid19Order.deathsAsc
                      : _Covid19Order.deathsDesc),
            ),
            if (showNew) const SizedBox.shrink(),
            InkWell(
              child: _buildText(
                (order == _Covid19Order.casesAsc
                        ? '↑ '
                        : order == _Covid19Order.casesDesc ? '↓ ' : '') +
                    'Cases',
                style: theme.textTheme.caption,
              ),
              onTap: () => setState(() => order =
                  order == _Covid19Order.casesDesc
                      ? _Covid19Order.casesAsc
                      : _Covid19Order.casesDesc),
            ),
            if (showNew) const SizedBox.shrink(),
          ])
        ],
        columnWidths: columnWidths,
        defaultColumnWidth: defaultColumnWidth,
      ),
      Expanded(
        child: SingleChildScrollView(
          child: Table(
            children: _buildRows(
              theme,
              api,
              showNew: showNew,
            ),
            columnWidths: columnWidths,
            defaultColumnWidth: defaultColumnWidth,
          ),
        ),
      ),
    ]);
  }

  List<TableRow> _buildRows(
    ThemeData theme,
    WhoApi api, {
    bool showNew = false,
  }) {
    final countries = [...api.countries];
    countries.sort((a, b) {
      switch (order) {
        case _Covid19Order.casesAsc:
          return a.latest.cumulativeCases.compareTo(b.latest.cumulativeCases);
        case _Covid19Order.casesDesc:
          return b.latest.cumulativeCases.compareTo(a.latest.cumulativeCases);
        case _Covid19Order.deathsAsc:
          return a.latest.cumulativeDeaths.compareTo(b.latest.cumulativeDeaths);
        case _Covid19Order.deathsDesc:
          return b.latest.cumulativeDeaths.compareTo(a.latest.cumulativeDeaths);
      }

      return 0;
    });

    return countries
        .map((country) => TableRow(children: [
              _buildText(country.name),
              _buildText(
                _formatNumber(country.latest.cumulativeDeaths),
                style: theme.textTheme.caption,
              ),
              if (showNew)
                _buildText(
                  country.latest.newDeaths > 0
                      ? '+${_formatNumber(country.latest.newDeaths)}'
                      : '-',
                  style: theme.textTheme.caption,
                ),
              _buildText(
                _formatNumber(country.latest.cumulativeCases),
                style: theme.textTheme.caption,
              ),
              if (showNew)
                _buildText(
                  country.latest.newCases > 0
                      ? '+${_formatNumber(country.latest.newCases)}'
                      : '-',
                  style: theme.textTheme.caption,
                ),
            ]))
        .toList(growable: false);
  }

  Widget _buildText(String data, {TextStyle style}) => Padding(
        child: Text(
          data,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
        padding: const EdgeInsets.all(8),
      );

  String _formatNumber(int v) => NumberFormat.compact().format(v);
}

enum _Covid19Order {
  casesAsc,
  casesDesc,
  deathsAsc,
  deathsDesc,
}
