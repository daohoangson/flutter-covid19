import 'package:covid19/api/who.dart';
import 'package:dart_countries_states/country_provider.dart';
import 'package:dart_countries_states/models/alpha2_codes.dart';
import 'package:dart_countries_states/models/country.dart';
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
        title: _CountryName(country.countryCode),
        trailing: HtmlWidget(
          '<span style="color: #D00">${_formatNumber(country.latest.deaths)}</span>'
          ' / '
          '<span style="color: #F90">${_formatNumber(country.latest.cases)}</span>',
        ),
      );

  String _formatNumber(int v) => NumberFormat.compact().format(v);
}

class _CountryName extends StatelessWidget {
  final String countryCode;

  const _CountryName(this.countryCode, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => FutureProvider<Country>(
        child: Consumer<Country>(
          builder: (_, country, __) => Text(country?.name ?? countryCode),
        ),
        create: (_) => CountryProvider()
            .getCountryByCode2(code2: Alpha2Code.valueOf(countryCode)),
      );
}
