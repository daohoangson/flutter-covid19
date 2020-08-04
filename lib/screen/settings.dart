import 'package:covid19/app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  static const kRouteName = '/settings';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: ListView(
          children: [
            _Heading('Preferences'),
            _PrefDarkTheme(),
            _PrefShowPerformanceOverlay(),
            _PrefUseHqMap(),
            _Heading('References'),
            _Reference(
              title: 'Cases & deaths data',
              subtitle: 'Official World Health Organization website',
              url: 'https://covid19.who.int',
            ),
            _Reference(
              title: 'High quality map',
              subtitle: 'mapsvg.com',
              url: 'https://mapsvg.com/maps/world',
            ),
            _Reference(
              title: 'Standard quality map',
              subtitle: 'simplemaps.com',
              url: 'https://simplemaps.com/resources/svg-world',
            ),
            _Reference(
              title: 'Flag icon set',
              subtitle: 'gosquared.com',
              url: 'https://github.com/gosquared/flags',
            ),
            _Reference(
              title: 'IP lookup',
              subtitle: 'ipdata.co',
              url: 'https://ipdata.co',
            ),
            _Heading('About'),
            _AboutAuthor(),
            _AboutVersion(),
            _AboutRepository(),
          ],
        ),
      );

  static Widget icon() => Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.settings),
          onPressed: () => Navigator.of(context).pushNamed(kRouteName),
          tooltip: 'Settings',
        ),
      );
}

class _AboutAuthor extends StatelessWidget {
  @override
  Widget build(BuildContext _) => ListTile(
        title: Text('Developer'),
        subtitle: Text('dao@hoangson.vn'),
        onTap: () => launch('https://hoangson.vn/?utm_source=covid19'
            '&utm_medium=about&utm_campaign=author'),
      );
}

class _AboutRepository extends StatelessWidget {
  @override
  Widget build(BuildContext _) => ListTile(
        title: Text('Repository'),
        subtitle: Text('github.com (GNU GPLv3)'),
        onTap: () => launch('https://github.com/daohoangson/flutter-covid19/'
            '?utm_source=covid19&utm_medium=about&utm_campaign=repository'),
      );
}

class _AboutVersion extends StatelessWidget {
  @override
  Widget build(BuildContext _) => FutureProvider(
        child: Consumer<PackageInfo>(
          builder: (_, info, __) => ListTile(
            title: Text('Version'),
            subtitle: Text('${info?.version} (build no. ${info?.buildNumber})'),
          ),
        ),
        create: (_) => PackageInfo.fromPlatform(),
      );
}

class _Heading extends StatelessWidget {
  final String title;

  const _Heading(this.title, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.headline6,
        ),
      );
}

class _PrefDarkTheme extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Selector<AppState, bool>(
        builder: (context, darkTheme, __) => ListTile(
          title: Text('Dark theme'),
          subtitle: Text(
            darkTheme == true
                ? 'Always use dark color scheme'
                : darkTheme == false
                    ? 'Always use light color scheme'
                    : 'Switch color scheme automatically',
          ),
          trailing: Checkbox(
            onChanged: (v) => AppState.of(context).darkTheme = v,
            tristate: true,
            value: darkTheme,
          ),
        ),
        selector: (_, app) => app.darkTheme,
      );
}

class _PrefShowPerformanceOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Selector<AppState, bool>(
        builder: (context, showPerformanceOverlay, __) => CheckboxListTile(
          onChanged: (_) {
            if (kIsWeb) {
              Scaffold.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "The performance overlay isn't supported on the web",
                  ),
                ),
              );
              return;
            }

            AppState.of(context).showPerformanceOverlay =
                !showPerformanceOverlay;
          },
          title: Text('Show performance overlay'),
          subtitle: Text("Toggle Flutter's performance overlay for kicks."),
          value: showPerformanceOverlay,
        ),
        selector: (_, app) => app.showPerformanceOverlay,
      );
}

class _PrefUseHqMap extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Selector<AppState, bool>(
        builder: (context, useHqMap, __) => CheckboxListTile(
          onChanged: (_) => AppState.of(context).useHqMap = !useHqMap,
          title: Text('Use HQ map'),
          subtitle: Text(
            'This app includes two maps with different level of details. '
            'The high quality map has roughly five times as many polygons as the standard one.',
          ),
          value: useHqMap,
        ),
        selector: (_, app) => app.useHqMap,
      );
}

class _Reference extends StatelessWidget {
  final String subtitle;
  final String title;
  final String url;

  const _Reference({
    Key key,
    @required this.subtitle,
    @required this.title,
    this.url,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: url != null ? () => launch(url) : null,
        title: Text(title),
        subtitle: Text(subtitle),
      );
}
