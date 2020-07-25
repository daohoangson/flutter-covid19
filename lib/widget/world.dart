import 'package:covid19/api/who.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Covid19World extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Consumer<WhoApi>(
        builder: (_, api, __) => api.isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : api.hasData
                ? ListView.builder(
                    itemBuilder: (context, index) =>
                        _CountryListTile(api.countries[index]),
                    itemCount: api.countries.length,
                  )
                : Text(api.error.toString()),
      );
}

class _CountryListTile extends StatelessWidget {
  final WhoCountry country;

  const _CountryListTile(this.country, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(country.name),
        trailing: HtmlWidget(
          '<span style="color: #D00">'
                  '${_formatNumber(country.latest.cumulativeDeaths)}' +
              (country.latest.newDeaths > 0
                  ? ' <span style="color: #ccc">+${_formatNumber(country.latest.newDeaths)}</span>'
                  : '') +
              '</span>'
                  ' / '
                  '<span style="color: #F90">'
                  '${_formatNumber(country.latest.cumulativeCases)}' +
              (country.latest.newCases > 0
                  ? ' <span style="color: #ccc">+${_formatNumber(country.latest.newCases)}</span>'
                  : '') +
              '</span>',
        ),
      );

  String _formatNumber(int v) => NumberFormat.compact().format(v);
}
