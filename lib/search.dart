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
  final Map<String, ApiCountry> searchIndex;

  CountryCodeSearchDelegate(Iterable<ApiCountry> countries)
      : searchIndex = Map.fromEntries(countries.map((c) =>
            MapEntry("${c.code.toLowerCase()} ${c.name.toLowerCase()}", c)));

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
            tooltip: 'Clear',
          ),
      ];

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
  Widget buildResults(BuildContext _) {
    final q = query.toLowerCase();
    final matchedKeys = searchIndex.keys
        .where((key) => key.contains(q))
        .toList(growable: false);

    return ListView.builder(
      itemBuilder: (context, index) {
        final country = searchIndex[matchedKeys[index]];
        return ListTile(
          title: Text(country.name),
          onTap: () => close(context, country.code),
        );
      },
      itemCount: matchedKeys.length,
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
