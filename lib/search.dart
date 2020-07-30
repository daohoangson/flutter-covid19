import 'package:covid19/api/api.dart';
import 'package:covid19/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CountryCodeSearchIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Consumer<Api>(
        builder: (context, api, child) => api.hasData
            ? IconButton(
                icon: Icon(Icons.search),
                onPressed: () => showSearch<String>(
                  context: context,
                  delegate: CountryCodeSearchDelegate(api.countries),
                ).then((v) {
                  if (v != null) AppState.of(context).highlightCountryCode = v;
                }),
                tooltip: 'Search',
              )
            : const SizedBox.shrink(),
      );
}

class CountryCodeSearchDelegate extends SearchDelegate<String> {
  final Map<String, String> index;

  CountryCodeSearchDelegate(Iterable<ApiCountry> countries)
      : index = Map.fromEntries(
            countries.map((c) => MapEntry(c.code, c.name.toLowerCase())));

  @override
  List<Widget> buildActions(BuildContext context) => [];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: AnimatedIcon(
          icon: AnimatedIcons.menu_arrow,
          progress: transitionAnimation,
        ),
        onPressed: () => close(context, null),
        tooltip: 'Back',
      );

  @override
  Widget buildResults(BuildContext context) {
    final q = query.toLowerCase();
    return SingleChildScrollView(
      child: Column(
        children: index.entries
            .where((e) => e.value.contains(q))
            .map((e) => ListTile(
                  title: Text(e.value),
                  onTap: () => close(context, e.key),
                ))
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
