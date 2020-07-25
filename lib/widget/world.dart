import 'package:covid19/api/who.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Covid19World extends StatelessWidget {
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
    final defaultColumnWidth = const FixedColumnWidth(60);

    return Column(children: [
      Table(
        children: [
          TableRow(children: [
            _buildText('Country', style: theme.textTheme.caption),
            _buildText('Deaths', style: theme.textTheme.caption),
            if (showNew) const SizedBox.shrink(),
            _buildText('Cases', style: theme.textTheme.caption),
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
  }) =>
      api.countries
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
