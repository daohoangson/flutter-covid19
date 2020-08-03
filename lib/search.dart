import 'package:covid19/data/api.dart';
import 'package:covid19/app_state.dart';
import 'package:covid19/data/ipapi/ipapi.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountrySearchButton extends StatelessWidget {
  final bool isFab;

  CountrySearchButton.icon() : isFab = false;

  CountrySearchButton.fab() : isFab = true;

  Widget get icon => Icon(Icons.search);

  String get tooltip => 'Search';

  @override
  Widget build(BuildContext context) => Consumer<Api>(
        builder: (context, api, child) => api.hasData
            ? isFab
                ? FloatingActionButton(
                    child: icon,
                    onPressed: () => _onPressed(context, api),
                    tooltip: tooltip,
                  )
                : IconButton(
                    icon: icon,
                    onPressed: () => _onPressed(context, api),
                    tooltip: tooltip,
                  )
            : const SizedBox.shrink(),
      );

  void _onPressed(BuildContext context, Api api) => showSearch<ApiCountry>(
        context: context,
        delegate: _CountrySearchDelegate(api.countries),
      ).then((country) {
        if (country != null)
          AppState.of(context).setHighlight(Highlighter.search, country);
      });
}

class _CountrySearchDelegate extends SearchDelegate<ApiCountry> {
  final Map<String, ApiCountry> searchIndex;
  final prefs = _SearchPreferences();

  _CountrySearchDelegate(Iterable<ApiCountry> countries)
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
          onTap: () => onTap(context, country),
        );
      },
      itemCount: matchedKeys.length,
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => query.isEmpty
      ? FutureBuilder<List<String>>(
          builder: (_, snapshot) => ListView.builder(
            itemBuilder: (_, index) {
              if (index == 0) return _IpBasedListTile(onTap: onTap);

              final recent = snapshot.data[index - 1];
              return ListTile(
                title: Text(recent),
                onTap: () async {
                  for (final country in searchIndex.values) {
                    if (country.name == recent) {
                      onTap(context, country);
                      return;
                    }
                  }
                },
              );
            },
            itemCount: (snapshot.hasData ? snapshot.data.length : 0) + 1,
          ),
          future: prefs.recents,
        )
      : buildResults(context);

  Future<void> onTap(BuildContext context, ApiCountry country) async {
    await prefs.addRecent(country.name);
    close(context, country);
  }
}

class _IpBasedListTile extends StatelessWidget {
  final Future<void> Function(BuildContext, ApiCountry) onTap;

  const _IpBasedListTile({Key key, @required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext _) => Selector<AppState, IpApi>(
        builder: (context, ipapi, _) => ListTile(
          onTap: ipapi.countryCode != null
              ? () {
                  final api = Provider.of<Api>(context, listen: false);
                  for (final country in api.countries) {
                    if (country.code == ipapi.countryCode) {
                      onTap(context, country);
                    }
                  }
                }
              : null,
          subtitle: ipapi.isLoading
              ? Text('Resolving your IP address...')
              : Text(ipapi.ip ?? 'N/A'),
          title: ipapi.title != null ? Text(ipapi.title) : null,
          trailing: ipapi.countryCode != null ? Icon(Icons.location_on) : null,
        ),
        selector: (_, app) => app.ipapi,
        shouldRebuild: (_, __) => true,
      );
}

class _SearchPreferences {
  static const kRecentsMax = 10;
  static const kRecentsPrefKey = 'search.recents';

  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  Future<List<String>> get recents =>
      prefs.then((p) => p.getStringList(kRecentsPrefKey));

  Future<void> addRecent(String v) async {
    final p = await prefs;

    final values = p.getStringList(kRecentsPrefKey) ?? <String>[];
    if (values.contains(v) == true) {
      if (values[0] == v) return;
      values.remove(v);
    }

    values.insert(0, v);
    while (values.length > kRecentsMax) values.removeLast();

    p.setStringList(kRecentsPrefKey, values);
  }
}
