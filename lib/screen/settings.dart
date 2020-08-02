import 'package:covid19/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen._({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: ListView(
          children: [
            _ShowPerformanceOverlay(),
          ],
        ),
      );

  static Widget icon() => Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.settings),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SettingsScreen._(),
          )),
        ),
      );
}

class _ShowPerformanceOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Selector<AppState, bool>(
        builder: (context, showPerformanceOverlay, __) => CheckboxListTile(
          onChanged: (_) => AppState.of(context).showPerformanceOverlay =
              !showPerformanceOverlay,
          title: Text('Show performance overlay'),
          value: showPerformanceOverlay,
        ),
        selector: (_, app) => app.showPerformanceOverlay,
      );
}
