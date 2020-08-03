import 'package:covid19/app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  static const kRouteName = '/settings';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: ListView(
          children: [
            _ShowPerformanceOverlay(),
            _UseHqMap(),
          ],
        ),
      );

  static Widget icon() => Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.settings),
          onPressed: () => Navigator.of(context).pushNamed(kRouteName),
        ),
      );
}

class _ShowPerformanceOverlay extends StatelessWidget {
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
          value: showPerformanceOverlay,
        ),
        selector: (_, app) => app.showPerformanceOverlay,
      );
}

class _UseHqMap extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Selector<AppState, bool>(
        builder: (context, useHqMap, __) => CheckboxListTile(
          onChanged: (_) => AppState.of(context).useHqMap = !useHqMap,
          title: Text('Use HQ map'),
          value: useHqMap,
        ),
        selector: (_, app) => app.useHqMap,
      );
}
